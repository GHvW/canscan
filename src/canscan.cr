# TCPSocket https://crystal-lang.org/api/0.21.0/TCPSocket.html
# TCPSocket.open &block will automatically close the connection, otherwise you need to manually close
require "socket"

# TODO: Write documentation for `Canscan`
module Canscan
  VERSION = "0.1.0"

  # TODO: Put your code here
  puts "Hello World!"

  # 1
  # TCPSocket.open("scanme.nmap.org", 80) do |conn|
  #   puts "Connection Successsful!"
  # end

  # 2
  # address = "scanme.nmap.org"
  # (1..1024).each do |i|
  #   # puts "scanning #{address}:#{i}"
  #   begin
  #     TCPSocket.open(address, i) do |conn|
  #       puts "#{address}:#{i} is open"
  #     end
  #   rescue
  #   end
  # end

  # 3 too fast
  # address = "scanme.nmap.org"
  # (1..1024).each do |i|
  #   # puts "scanning #{address}:#{i}"
  #   spawn do
  #     ->(n : Int32) {
  #       begin
  #       TCPSocket.open(address, i) do |conn|
  #         puts "#{address}:#{i} is open"
  #       end
  #     rescue
  #     end
  #     }.call(i)
  #   end
  # end

  # 4 better, but will show inconsistent results, with spawn macro
  done_chan = Channel(Nil).new

  address = "scanme.nmap.org"
  (1..1024).each do |i|
    # puts "scanning #{address}:#{i}"
    spawn ->(n : Int32) {
      begin
        TCPSocket.open(address, i) do |conn|
          puts "#{address}:#{i} is open"
        end
      rescue
      end
      done_chan.send(nil)
    }.call(i)
  end

  (1..1024).each do # how we wait since we dont have a WaitGroup like Go
    done_chan.receive
  end
end
