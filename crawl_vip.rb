# -*- coding: utf-8 -*-

require 'rubygems'
$:.unshift('lib')
require 'bot2ch'
require 'worker'

@worker = Worker.new(3)
@menu = Bot2ch::Menu.new

@menu.get_board('news4vip').threads.each{|th|
  @worker.add{|w|
    puts "#{w.tasks.length} #{th.title} #{th.posts.length}"
  }
}

sleep 10000000000
