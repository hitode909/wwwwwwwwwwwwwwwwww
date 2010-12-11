require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'rss'

ROOT = "http://matome-plus.com/"

def get(url)
  warn "get #{url}"
  Nokogiri::HTML(open(url))
end

module Enumerable
  def each_with_logging(&block)
    len = self.length
    self.each_with_index{|a, index|
      warn "#{caller.first} #{index+1} / #{len}"
      yield a
    }
  end
end

def ignore_error(&block)
  begin
    block.call
  rescue => error
    warn error
  end
end

def process_rss(rss_url)
  ignore_error {
    source = open(rss_url)
    rss = begin RSS::Parser.parse(source) rescue RSS::Parser.parse(source, false) end
    warn rss.channel.title
    rss.items.each_with_logging{|item|
      puts item.title
    }
  }
end

def process_blog(blog_url)
  ignore_error {
    page = get(blog_url)
    process_rss(page.at("link[rel='alternate']")["href"])
  }
end

def process_page(page_url)
  ignore_error {
    warn page_url
    get(page_url).search(".sitename a").each_with_logging{|blog|
      process_blog(blog["href"])
    }
  }
end

ignore_error {
  first_page = get(ROOT)

  first_page.search(".pagination a").each_with_logging{|page|
    process_page(ROOT + page["href"])
  }
}
