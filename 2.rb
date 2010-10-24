# -*- coding: utf-8 -*-

require 'rubygems'
$:.unshift('lib')
require 'bot2ch'
require 'MeCab'

menu = Bot2ch::Menu.new
board = menu.get_board('news4vip')

thread = board.threads.sort_by{|t| t.speed}.reverse.first
# thread = Bot2ch::Thread.new('http://yuzuru.2ch.net/test/read.cgi/news4vip/1286724144/l50', '声優だけど質問ある？')

# TODO
# 表示するときに，>>で参照されてるやつをすぐ下にもってくる
# ただし，親のスコアのほうが大きいときだけもってくる

# トピック抽出?????????

# 表示の工夫，画像展開，リンク

# 1の発言
# user_id = thread.post_at(1).user_id
# thread.posts.select{|post| post.user_id == user_id}.each{|post|
#   post.score += 1
# }

# 母子参照
thread.posts.each{ |post|
  post.body.scan(/&gt;&gt;(\d+)/).each{|match|

    number = match[0].to_i
    parent = thread.post_at(number)

    thread.set_family(parent,post) if parent 
      
  }
}

[/ttp/].each{|rule|
  thread.posts.each{|post|
    post.score += post.body.scan(rule).length
  }
}



puts "<html><title>#{thread.title}</title><body>"
puts '<style> .owner { color: #3333ff; font-weight: bold; } .topic { margin-bottom: 2em; background: #ffffcc; border: 1px gray solid;}</style>'

# スコアついてるやつ表示
thread.posts.select{|post| post.primary? }.each{|post|
  puts '<div class="topic">'
  post.to_html
  post.descendant.select{|post| post.scored?}.each{|post|
    post.to_html
  }
  puts '</div>'
}

#thread.posts.select{|post| post.score > 0}.each{|post|
#thread.post_at(48).to_html
#thread.post_at(48).descendant.each{|post|
#  post.to_html
  # puts "<font size='3em'><div>#{post.index}<br>#{post.body}</font></div>"
#}
puts "</body></html>"
