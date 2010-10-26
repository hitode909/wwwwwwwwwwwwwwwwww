# -*- coding: utf-8 -*-

require 'rubygems'
$:.unshift('lib')
require 'bot2ch'
require 'worker'

@worker = Worker.new
@menu = Bot2ch::Menu.new

def add_job
  @worker.add{|w|
    th = @menu.boards.sample.threads.sample
    puts "#{th.title} #{th.url}\n\t#{th.posts.last.body}"
    add_job
  }
end

20.times{
  add_job
}

loop {
  sleep 10000000000
}
