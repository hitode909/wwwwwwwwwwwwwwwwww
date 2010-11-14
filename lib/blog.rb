# -*- coding: utf-8 -*-
require 'atomutil'

module Atompub # support hatena
  class HatenaClient < Client
    def publish_entry(uri)
      @hatena_publish = true
      update_resource(uri, ' ', Atom::MediaType::ENTRY.to_s)
    ensure
      @hatena_publish = false
    end

    private
    def set_common_info(req)
      req['X-Hatena-Publish'] = 1 if @hatena_publish
      super(req)
    end
  end
end

module Blog
  require "erb"
  class Entry
    include  ERB::Util
    attr_accessor :title
    def initialize(title,posts)
      @title = title
      @posts = posts
    end

    def process_file(filename)
      erb = ERB.new(open(File.expand_path(File.dirname(__FILE__) + filename)).read, nil, '-')
      erb.result(binding)
    end

    def to_html
      process_file("/entry.erb")
    end

    def to_hatena_body
      process_file("/entry_hatena.erb")
    end
  end

  class HatenaDiaryWriter
    def initialize(username, password)
      @auth = Atompub::Auth::Wsse.new :username => username, :password => password
      @client = Atompub::HatenaClient.new :auth => @auth
      @service = @client.get_service "http://d.hatena.ne.jp/#{username}/atom"
    end

    def post(entry)
      self._post(entry, @service.workspace.collections[1].href)
    end

    def post_draft(entry)
      self._post(entry, @service.workspace.collections[0].href)
    end

    protected
    def _post(entry, uri)

      atom_entry = Atom::Entry.new(
        :title => entry.title,
        :updated => Time.now
        )
      require 'rexml/document'
      atom_entry.content = Atom::Content.new(:type => 'xhtml', :body => self.rexml_element_from_text(entry.to_hatena_body))
      @client.create_entry uri, atom_entry
    rescue => error
      warn error
      exit
    end

    def rexml_element_from_text(text)
      timeout(6) {
        loop {
          begin
            return REXML::Document.new('<?xml version="1.0"?><div>' + text + '</div>').root
          rescue  TimeoutError => error
            raise error
          rescue => error
            if error.message =~ /Undeclared entity '(.+)' in raw string/
            warn "remove #{$1}"
              text.gsub!($1, "")
            elsif error.message =~ /Illegal character '&' in raw string "(.+)"/
              warn "remove & from #{$1}"
              text.gsub!($1, $1.gsub("&", "&amp;"))
            else
              raise error
            end
          end
        }
      }
    end
  end
end
