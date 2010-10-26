# -*- coding: utf-8 -*-

require 'rubygems'
$:.unshift('lib')
require 'bot2ch'
require 'worker'

@worker = Worker.new(5)
@menu = Bot2ch::Menu.new

@menu.boards.sort_by{rand}.each{|b|
  # @worker.add{|w|
  puts "#{@worker.tasks.length} #{b.url}"
  b.threads rescue next
  b.clone.threads.each{|th|
    @worker.add{|w|
      th.dup.get_resource
      puts "#{w.tasks.length} #{th.title}"
    }
  }
  while @worker.tasks.length > 10
    sleep 0.5
  end
  GC.start if rand < 0.1
  # }
}

while @worker.tasks.length > 0
  sleep 0.5
end

puts "done"
