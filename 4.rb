# -*- coding: utf-8 -*-

require 'rubygems'
$:.unshift('lib')
require 'bot2ch'
require 'blog'

menu = Bot2ch::Menu.new
board = menu.get_board('news4vip')

thread = board.threads.sort_by{|t| t.speed}.reverse[2]
# thread = Bot2ch::Thread.new('http://yuzuru.2ch.net/test/read.cgi/news4vip/1286724144/l50', '声優だけど質問ある？')

# TODO
# 表示するときに，>>で参照されてるやつをすぐ下にもってくる
# ただし，親のスコアのほうが大きいときだけもってくる

# トピック抽出?????????

# 表示の工夫，画像展開，リンク

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

require "pp"
puts "<pre>"
pp thread.keywords 
puts "</pre>"
thread.keywords.keys.each{|rule|
  next if rule.match(/\./)
  thread.posts.select{|post| post.body.match rule }.each{|post|
    post.score += thread.keywords[rule].to_i

  }
}
# thread.posts.each{|post| p  post.standard_score }
# exit


# スコアついてるやつ表示
puts Blog::Entry.new(thread.title,thread.posts.select{|post| post.standard_score  >= 10 }).to_html


