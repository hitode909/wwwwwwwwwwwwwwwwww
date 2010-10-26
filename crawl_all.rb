# -*- coding: utf-8 -*-

require 'rubygems'
$:.unshift('lib')
require 'bot2ch'
require 'worker'

@worker = Worker.new(10)
@menu = Bot2ch::Menu.new

@menu.boards.each{|b|
  @worker.add{|w|
    b.threads rescue next
    b.threads.each{|th|
      @worker.add{|w|
        puts "#{w.tasks.length} #{th.title} #{th.posts.length}"
      }
    }
  }
}

sleep 10000000000
