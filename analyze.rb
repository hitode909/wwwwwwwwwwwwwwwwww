# -*- coding: utf-8 -*-

require 'rubygems'
$:.unshift('lib')
require 'bot2ch'
require 'analyzer'

menu = Bot2ch::Menu.new

analyzer = Analyzer.new
board = menu.get_board('news4vip')

begin
  analyzer.documents = Marshal.load(open('dump'))
rescue
  board.threads.each_with_index{|th, index|
    analyzer.add_document(th.all_body_text)
    puts "#{index} #{th.title}"
  }

  open('dump', 'w'){|f|
    f.write(Marshal.dump(analyzer.documents))
  }
end

fast_thread = board.threads.sort_by{|t| t.speed}.reverse.first

doc = analyzer.document_from_body(fast_thread.all_body_text)

# %w{ポケモン フシギダネ 俺 嫁 アニソン 将棋 野球 交換 対戦 バトル}.each{|noun|
doc.nouns.uniq.map{|noun|
  warn noun
  [noun, analyzer.tfidf(fast_thread.all_body_text, noun)]
}.sort_by{|pair| pair[1]}.each{|pair|
  puts "#{pair[0]},#{pair[1]}"
}
