#!/usr/bin/env ruby

require 'redis'

unless ARGV.length == 2 || ARGV.length == 4
  puts "#{$PROGRAM_NAME} source destination"
  puts 'or'
  puts "#{$PROGRAM_NAME} source source_port destination destination_port"
  exit 1
end

src_host = ARGV[0]

if ARGV.length == 4
  src_port = ARGV[1]
  dst_host = ARGV[2]
  dst_port = ARGV[3]

  src_monitor_conn = Redis.new(host: src_host, port: src_port)
  src_conn = Redis.new(host: src_host, port: src_port)
  dst_conn = Redis.new(host: dst_host, port: dst_port)
else
  dst_host = ARGV[1]

  src_monitor_conn = Redis.new(host: src_host)
  src_conn = Redis.new(host: src_host)
  dst_conn = Redis.new(host: dst_host)
end

abort('No keys found') if src_conn.dbsize.zero?

def key_migration(key, dst_conn, ttl, dump)
  ttl == -1 ? dst_conn.restore(key, 0, dump) : dst_conn.restore(key, ttl, dump)
end

Thread.new do
  loop do
    exit if $stdin.gets =~ /(?:qu|ex)it/i
  end
end

# Start Monitor
log = []
Thread.new do
  src_monitor_conn.monitor do |line|
    log << line if line.include?('"set"') || line.include?('"incr"')
  end
end

# Initial Migration of Keys
src_conn.keys.each do |key|
  skip if key == 'ElastiCacheMasterReplicationTimestamp'

  ttl = src_conn.ttl(key)
  dump = src_conn.dump(key)
  key_migration(key, dst_conn, ttl, dump)
end

puts 'The keys have been restored to the destination server'
puts 'Monitoring for key updates...'
puts 'Type Quit or Exit to quit.'

loop do
  # Migrate Any Updated Keys
  modified_keys = log.map(&:split).map { |elem| elem[4].slice(1..-2) }
  modified_keys.uniq!

  modified_keys.each do |key|
    puts "Updating key: #{key}"

    ttl = src_conn.ttl(key)
    dump = src_conn.dump(key)
    dst_conn.del(key)
    key_migration(key, dst_conn, ttl, dump)
    log.delete_if { |line| line.include?(key) }
  end

  sleep 0.1
end
