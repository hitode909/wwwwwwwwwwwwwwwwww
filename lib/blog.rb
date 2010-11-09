module Blog
  require "erb"
  class Entry
include  ERB::Util
    def initialize(title,posts)
      @title = title
      @posts = posts
      @erb = ERB.new(self.template)
    end

    def template
      @script ||= begin
                    path = File.expand_path(File.dirname(__FILE__) + "/entry.erb")
                    open(path).read
                  end
    end

    def to_html
       @erb.result(binding)
    end
  end
end
