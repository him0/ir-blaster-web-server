require 'sqlite3'

# project root での実行
db = SQLite3::Database.new './db/devices.db'

# create devices table
sql = <<-SQL
CREATE TABLE devices (
  id INTEGER primary key,
  name TEXT UNIQUE NOT NULL,
  mac_address TEXT NOT NULL,
  ip TEXT NOT NULL,
  port INTEGER NOT NULL
);
SQL
db.execute(sql)

# create commands table
sql = <<-SQL
CREATE TABLE commands (
  id INTEGER primary key,
  device_id INTEGER NOT NULL,
  name TEXT UNIQUE NOT NULL,
  data TEXT NOT NULL,
  FOREIGN KEY (device_id)
    REFERENCES devices(id) 
);
SQL
db.execute(sql)

puts 'Database initialization is success!'