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
  # done_chan = Channel(Nil).new

  # address = "scanme.nmap.org"
  # (1..1024).each do |i|
  #   # puts "scanning #{address}:#{i}"
  #   spawn ->(n : Int32) {
  #     begin
  #       TCPSocket.open(address, i) do |conn|
  #         puts "#{address}:#{i} is open"
  #       end
  #     rescue
  #     end
  #     done_chan.send(nil)
  #   }.call(i)
  # end

  # (1..1024).each do # how we wait since we dont have a WaitGroup like Go
  #   done_chan.receive
  # end

  # 5, shows out of order if using multithread preview `crystal build -Dpreview_mt ./src/canscan`, otherwise it mostly is in order
  # def self.worker(ports, done)
  #   while !ports.closed?
  #     puts ports.receive
  #     done.send(true)
  #   end
  # end

  # ports_chan = Channel(Int32).new(100) # pool of 100 workers
  # done_chan = Channel(Bool).new

  # 100.times do
  #   spawn worker(ports_chan, done_chan)
  # end

  # spawn do
  #   (1..1024).each do |i|
  #     ports_chan.send(i)
  #   end
  # end

  # 1024.times do
  #   done_chan.receive
  # end

  # ports_chan.close

  # 6, compiled with crystal build --Dpreview_mt ./src/canscan
  def self.worker(ports, results)
    address = "scanme.nmap.org"
    while !ports.closed?
      begin
        i = ports.receive
        TCPSocket.open(address, i) do |conn|
          results.send(i)
        end
      rescue Channel::ClosedError # workers will be waiting on receive, when the channels are closed, this error will throw so we need to catch it!
      rescue Socket::ConnectError
        results.send(0)
      end
    end
  end

  ports_chan = Channel(Int32).new(100) # pool of 100 workers
  results_chan = Channel(Int32).new

  100.times do
    spawn worker(ports_chan, results_chan)
  end

  spawn do
    (1..1024).each do |i|
      ports_chan.send(i)
    end
  end

  open_ports = [] of Int32
  (1..1024).each do
    result = results_chan.receive
    if result != 0
      open_ports << result
    end
  end

  ports_chan.close
  results_chan.close

  puts "open ports: #{open_ports}"

  puts "Bye Bye"
end
