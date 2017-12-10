require "sqlite3"

class DB
  attr_reader :db

  def initialize
    # project root での実行
    @db = SQLite3::Database.new './db/devices.db'
    @db.results_as_hash = true
  end

  def all
    @db.execute('SELECT * FROM devices;').map do |device|
      {
        id: device['id'],
        name: device['name'],
        mac_address: device['mac_address'],
        ip: device['ip'],
        port: device['port']
      }
    end
  end

  def register_device(name, mac_address, ip, port)
    @db.execute('INSERT INTO devices (name, mac_address, ip, port) values (?, ?, ?, ?);', name, mac_address, ip, port)
    device = @db.execute('SELECT * FROM devices WHERE ROWID=last_insert_rowid();').last
    return nil unless device
    {
      id: device['id'],
      name: device['name'],
      mac_address: device['mac_address'],
      ip: device['ip'],
      port: device['port']
    }
  end

  def find_device_by(name)
    device = @db.get_first_row('SELECT * FROM devices WHERE name="' + name + '";')
    return nil unless device
    {
      id: device['id'],
      name: device['name'],
      mac_address: device['mac_address'],
      ip: device['ip'],
      port: device['port']
    }
  end

  def get_command_data_by(name)
    command = @db.get_first_row('SELECT * FROM commands WHERE name="' + name + '";')
    return nil unless command
    return JSON.parse(command['data'])
  end

  def delete_device(name)
    @db.execute('DELETE FROM devices WHERE name=?;', name)
  end

  def commands(device_id)
    commands = @db.execute('SELECT id, name FROM commands WHERE device_id=?;', device_id).map do |row|
      {
        id: row['id'],
        name: row['name']
      }  
    end
    return [] unless commands
    commands
  end

  def register_command(device_id, command_name, data)
    @db.execute('INSERT INTO commands (device_id, name, data) values (?, ?, ?);', device_id, command_name, data.to_json)
    command = @db.execute('SELECT * FROM commands WHERE ROWID=last_insert_rowid();').last
    return nil unless command
    {
      id: command['id'],
      name: command['name'],
      data: command['data']
    }
  end

  def delete_command(name)
    @db.execute('DELETE FROM commands WHERE name=?;', name)
  end
end
