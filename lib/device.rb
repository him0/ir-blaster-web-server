class Device
  class << self
    # たまに動くけど動かない条件がわからない。
    def discover
      discovered = ::BroadlinkRM::Device.discover.to_hash.tap do |h|
        h[:mac] = h[:mac].map{ |byte| byte.to_s(16).rjust(2, "0") }.join(":")
        h[:device_id] = normalize_mac_address(h[:mac])
      end
      {
        mac_address: discovered[:mac],
        ip: discovered[:host],
        port: discovered[:port]
      }
    end

    # device key の一覧
    def all
      db = DB.new()
      db.all
    end

    # params: {
    #   name: 'xxx',
    #   mac_address: 'xxxxxxx',
    #   ip: '192.168.x.x',
    #   port: 0000 
    # }
    # return: mac address を単純にしたもの
    def create!(params)
      db = DB.new()
      params = db.register_device(params[:name], params[:mac_address], params[:ip], params[:port])
      Device.new(params)
    end

    def delete!(params)
      db = DB.new()
      db.delete_device(params[:name])
    end

    def find_by_name(name)
      db = DB.new()
      Device.new(db.find_device_by(name))
    end

    # MAC Address の整形
    def normalize_mac_address(mac_address)
      if mac_address.is_a?(Array)
        mac_address.map{ |e| e.is_a?(Integer) ? e.to_s(16).rjust(2,"0") : e }.join("")
      elsif mac_address.is_a?(String)
        mac_address.gsub(":", "")
      else
        mac_address.to_s
      end
    end

    def mac_to_byte_array(mac_address)
      normalize_mac_address(mac_address).scan(/.{2}/).map{|byte| byte.to_i(16)}
    end
  end

  attr_reader :id, :name, :mac_address, :ip, :port

  def initialize(params)
    @db = DB.new()
    @id = params[:id]
    @name = params[:name]
    @mac_address = params[:mac_address]
    @ip = params[:ip]
    @port = params[:port]

    @broadlink_device = ::BroadlinkRM::Device.new(
      host: @ip,
      port: @port,
      mac:  self.class.mac_to_byte_array(@mac_address)
    )
    @broadlink_device.auth
  end

  def learn(command_name, time_to_wait_seconds=10)
    if time_to_wait_seconds > 30
      raise "time_to_wait should not be larger than 30 seconds. We wouldn't want to lock up the device"
    end
    @broadlink_device.enter_learning
    sleep(time_to_wait_seconds % 31)
    command = @broadlink_device.check_data
    @db.register_command(@id, command_name, command)
  end

  def commands
    @db.commands(@id)
  end

  def execute_command(command_name)
    @broadlink_device.send_data(@db.get_command_data_by(command_name))
  end

  def delete_command(name)
    @db.delete_command(name)
  end
end
