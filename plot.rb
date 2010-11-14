# -*- coding: utf-8 -*-

require 'rubygems'
$:.unshift('lib')
require 'bot2ch'
require 'blog'

menu = Bot2ch::Menu.new
board = menu.get_board('news4vip')


thread = menu.boards.sample.threads.sample

# thread = board.threads.sort_by{|t| t.speed}.reverse[2]

# 1の発言
iti = 100
user_id = thread.post_at(1).user_id
thread.posts.select{|post| post.user_id == user_id}.each{|post|
  post.score += iti
  iti /= 2
}

# 母子参照

thread.posts.each{ |post|
  post.body.scan(/&gt;&gt;(\d+)/).each{|match|
      
    number = match[0].to_i
    parent = thread.post_at(number)
      
    thread.set_family(parent,post) if parent 
  }
}

thread.keywords.keys.each{|rule|
  next if rule.match(/\./)
  thread.posts.select{|post| post.body.match rule }.each{|post|
    post.score += thread.keywords[rule].to_i

  }
}


puts thread.posts.map{|post| "#{post.standard_mentions_count} #{post.standard_score}"}.join("\n")


