# -*- coding: utf-8 -*-
require 'json'
require 'net/http'

module Bot2ch
  class Thread
    attr_accessor :dat, :title, :created_on, :posts_length


    def initialize(url, title, posts_length, created_on = Time.now)
      @dat = url
      @title = title.strip
      @posts_length = posts_length
      @created_on = created_on
    end

    def url
      list = @dat.split('/').reject{|f| f == ''}
      "http://#{list[1]}/test/read.cgi/#{list[2]}/#{list[4].scan(/\d/).join}"
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

    def all_body_text_yahoo
      self.all_body_text.gsub(/[^ ]*:\/\/[^ ]*/, "").gsub(/&|=|\?|#|<[^>]>|>>\d+/, '').gsub(/\n+/, "\n").gsub(/( |　)+/, ' ')[1..30000]
    end

    # iは1から
    def post_at(i)
      posts[i-1]
    end

    def get_resource
      CachedResource.resource(@dat)
    end

    def posts
      return @posts if @posts
      index = 1
      CachedResource.resource(@dat) do |f|
        lines = f.read.toutf8
        @posts = lines.each_line.map {|line|
          begin
            raise if line == "あぼーん"
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
          rescue
            # warn "failed to parse: #{line}"
            post = Post::Deleted.new
            post.thread = self
            index += 1
            post
          end
        }
      end
    end

    def set_family(parent,child)
      return unless child.index > parent.index
      return if parent.children.include?(child)
      parent.set_child(child)
      child.set_parent(parent)
    end

    def dat_no
      File.basename(@dat, '.dat')
    end

    def speed
      self.posts_length / (Time.now - self.created_on) * (3600 * 24)
    end

    def title_and_length
      "#{title}(#{posts_length})"
    end

    def keywords
     return @keywords if @keywords
      Net::HTTP.version_1_2
      self.net_http_class.start('jlp.yahooapis.jp', 80) {|http|
        data = "output=json&appid=RZv4ed6xg67n15cyyGFF8Io0r3i.o0uwISXfrFOZYyMghbdeNA10_M6KemHLqz0laQ--&sentence=#{self.all_body_text_yahoo}"
        response = http.post('/KeyphraseService/V1/extract',data)
        @keywords = JSON.parse(response.body)
      }
    end

    def net_http_class
      proxy_env = ENV['HTTP_PROXY'] or ENV['http_proxy']
      return Net::HTTP unless proxy_env
      host, port = proxy_env.match(/http:\/\/(.+):(\d+)/).to_a.values_at(1,2)
      return Net::HTTP unless host and port
      warn "using proxy #{[host, port]}"
      return Net::HTTP::Proxy(host, port)
    end

    def collect_mentions
      self.posts.each{|post|
        post.add_mention(nil)
        post.body.scan(/&gt;&gt;(\d+)/).flatten.each{|num|
          self.post_at(num.to_i).add_mention(post.index)
        }
      }
    end

    def self.register(*names)
      Bot2ch::Post.register(*names)
      names.each{|name|
        define_method("average_#{name}".to_sym){
          @cache ||= {}
          @cache[name] ||= self.posts.map(&name).inject{|a,b| a+b} / self.posts.length.to_f
        }

        define_method("deviation_#{name}".to_sym) {
          @cache ||= {}
          @cache[name] ||= 
          Math.sqrt(self.posts.map(&name).inject{|a,b| a+(b - self.send("average_#{name}".to_sym))**2 } / self.posts.length.to_f)
        }
      }
    end
    self.register :score,:mentions_count,:keyword_rate
  end
end
