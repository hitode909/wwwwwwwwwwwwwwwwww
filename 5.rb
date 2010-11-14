# -*- coding: utf-8 -*-

require 'rubygems'
$:.unshift('lib')
require 'bot2ch'
require 'blog'
require 'pit'

account = Pit.get("hatena", :require => {
                    :username => "hatena_id",
                    :password => "password"
                  })

menu = Bot2ch::Menu.new
# thread = menu.boards.sample.threads.sample

board = menu.get_board('news4vip')
thread = menu.boards.sample.threads.sample

# 1の発言
iti = 100
user_id = thread.post_at(1).user_id
thread.posts.select{|post| post.user_id == user_id}.each{|post|
  post.score += iti
  iti /= 2
}

require "pp"
pp thread.keywords

# スコア付け
thread.keywords.keys.each{|rule|
  next if rule.match(/\./)
  thread.posts.select{|post| post.body.match rule }.each{|post|
    post.score += thread.keywords[rule].to_i
  }
}

sorted_scores = thread.posts.map(&:standard_score).sort.reverse
want = thread.posts.length / 10
threshold = sorted_scores[want] || 10

# 記事投稿 いきなり投稿されるので気をつける!!!!!
writer = Blog::HatenaDiaryWriter.new(account[:username], account[:password])
entry = Blog::Entry.new(thread.title_and_length, thread.posts.select{|post| post.standard_score  >= threshold })
puts entry.title
writer.post(entry)

puts "http://d.hatena.ne.jp/#{ENV['hatena_username']}/"
