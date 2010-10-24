# -*- coding: utf-8 -*-
# Bot2ch
# Copyright (c) 2009 Kazuki UCHIDA
# Licensed under the MIT License:
#   http://www.opensource.org/licenses/mit-license.php

require 'open-uri'
require 'kconv'
require 'yaml/store'
require 'net/http'
require 'cgi'
require 'cached_resource'

module Bot2ch
  class Menu
    def initialize
      @bbsmenu = 'http://menu.2ch.net/bbsmenu.html'
    end

    def get_board(subdir)
      reg = Regexp.new("href=(.+#{subdir})", Regexp::IGNORECASE)
      CachedResource.resource(@bbsmenu) do |f|
        f.each do |line|
          return Board.new($1) if line.encode("utf-8", "sjis") =~ reg
        end
      end
    end
  end

  class Board
    def initialize(url)
      @url = url
      @subject = "#{url}/subject.txt"
    end

    def get_threads
      threads = []
      CachedResource.resource(@subject) do |f|
        lines = f.read.toutf8
        lines.each_line do |line|
          dat, title = line.split('<>')
          created_on = Time.at(dat.to_i)
          threads << Thread.new("#{@url}/dat/#{dat}", title, created_on)
        end
      end
      threads
    end

    def threads
      @threads ||= get_threads
    end
  end

  class Thread
    attr_accessor :dat, :title, :created_on

    def initialize(url, title, created_on = Time.now)
      @dat = url
      @title = title.strip
      @created_on = created_on
    end

    def url
      list = @dat.split('/').reject{|f| f == ''}
      "http://#{list[1]}/test/read.cgi/#{list[2]}/#{list[4].scan(/\d/)}"
    end

    def get_images
      images = []
      downloaders = [NormalImageDownloader, ImepitaDownloader]
      CachedResource.resource(@dat) do |f|
        lines = f.read.toutf8
        lines.each do |line|
          contents = line.split('<>')[3]
          while contents =~ /\/\/[-_.!~*\'()a-zA-Z0-9;\/?:\@&=+\$,%#]+/i
            url = "http:#{$&}"
            contents = $'
            image_downloader = downloaders.find { |d| d.match(url) }
            next unless image_downloader
            images << image_downloader.new(url)
          end
        end
      end
      images
    end

    def all_body_text
      self.posts.map(&:body_text).join("\n")
    end

    # iは1から
    def post_at(i)
      posts[i-1]
    end
    
    def posts
      return @posts if @posts
      index = 1
      CachedResource.resource(@dat) do |f|
        lines = f.read.toutf8
        @posts = lines.each_line.map do |line|
          post = Post.new
          post.thread = self
          name, email, _date, body = line.split('<>')
          date = Time.local(*_date.scan(/\d+/)[0..5])
          user_id = _date.scan(/ID:(.*)$/).flatten.first
          %w{name email date user_id body index}.each{ |key|
            eval "post.#{key} = #{key}"
          }
          post.thread = self
          index += 1
          post
        end
      end
    end

    def set_family(parent,child)
      return unless child.index > parent.index
      parent.set_child(child) 
      child.set_parent(parent)
    end

    def dat_no
      File.basename(@dat, '.dat')
    end
  end

  class Post
    attr_accessor :thread, :name, :email, :date, :body, :index, :user_id, :thread, :score,:parents,:children

    def is_owner
      self.thread.post_at(1).user_id == self.user_id
    end

    def to_html
      color = self.score > 3 ? 'red' : self.score > 1 ? 'blue' : 'black'
      puts '<dl class="thread" style="font-size: ' + (Math.log(self.score + 10) - 1.5).to_s + 'em; color: ' + color + '" >'
      puts '<dt hb:annotation="true">'
      puts self.index
      puts '：<font color="green"><b>'
      puts self.is_owner ? '<span class="owner">' : '<span>'
      puts self.name
      puts '</span>'
      puts '</b></font>：'
      puts self.date
      puts 'ID:'
      puts self.user_id

      puts '</dt><dd>'
      puts self.body
      puts '</dd></dl>'
    end

    def initialize
      @score  =  0
      @parents = []
      @children = []
    end

    def url
      "#{self.thread.url}/#{self.index}"
    end

    def body_text
      CGI.unescapeHTML(self.body.gsub(/<br>/, '').gsub(/http[^\s]+/, '').gsub(/<\/?a[^>]*>/, ''))
    end



    def set_child(post)
      return if @children.include?(post) or post.index < self.index
      @children << post
      @score +=1
    end

    def set_parent(post)
      return if @parents.include?(post) or post.index > self.index
      @parents << post
      @score +=1
    end

    def scored?
      self.score > 0
    end

    def primary?
      self.parents.empty? && scored?
    end
    
    def descendant
      @children.concat(@children.map(&:descendant).flatten).uniq.sort_by{|post| post.index}
    end

  end

  class Downloader
    attr_accessor :uri, :url

    def initialize(url)
      @url = url
      @uri = URI.parse(@url)
    end

    def save(res, saveTo)
      puts "download: #{url}"
      case res
      when Net::HTTPSuccess
        open(saveTo, 'wb') do |f|
          f.write res.body
        end
      end
    end
  end

  class NormalImageDownloader < Downloader
    def download(saveTo)
      http = Net::HTTP.new(uri.host, 80)
      res = http.get(uri.path)
      save(res, saveTo)
    end

    def self.match(url)
      url =~ /.jpg$/i
    end
  end

  class ImepitaDownloader < Downloader
    def download(saveTo)
      http = Net::HTTP.new(uri.host, 80)
      headers = {'Referer' => url}
      res = http.get("/image#{uri.path}", headers)
      save(res, saveTo)
    end

    def self.match(url)
      url =~ /\/\/imepita.jp\/\d+\/\d+/i
    end
  end

  class App
    def execute(subdir)
      root_dir = File.dirname(__FILE__)
      image_dir = "#{root_dir}/images"
      log_dir = "#{root_dir}/log"
      FileUtils.mkpath(image_dir) unless File.exists?(image_dir)
      FileUtils.mkpath(log_dir) unless File.exists?(log_dir)

      db = YAML::Store.new("#{log_dir}/thread.db")
      menu = Menu.new
      board = menu.get_board(subdir)
      threads = board.get_threads
      puts "total: #{threads.length} threads"
      threads.each do |thread|
        images = thread.get_images rescue next
        next if images.empty?
        parent_dir = "#{image_dir}/#{thread.dat_no}" 
        Dir.mkdir(parent_dir) unless File.exists?(parent_dir)
        puts "#{thread.title}: #{images.length} pics"
        downloaded = db.transaction { db[thread.dat_no] } || 0
        images.each_with_index do |image, index|
          next if index < downloaded
          image.download("#{parent_dir}/#{index}.jpg") rescue next
          sleep(0.2)
        end
        db.transaction { db[thread.dat_no] = images.length }
      end
    end
  end
end

if __FILE__ == $0
  begin
    Bot2ch::App.new.execute('news4vip')
  rescue
    puts 'Bot Error'
  end
end
