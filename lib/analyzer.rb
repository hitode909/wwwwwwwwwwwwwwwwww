# -*- coding: utf-8 -*-
require 'MeCab'

class Analyzer
  attr_accessor :documents
  def initialize
    @togger = MeCab::Tagger.new('-O wakati')
    @documents = []
  end

  def document_from_body(body)
    doc = Document.new
    doc.body = body
    doc.nouns = nouns(body)
    doc
  end

  def add_document(body)
    @documents << document_from_body(body)
  end

  def nouns(body)
    list = []
    node = @togger.parseToNode(body)
    while node
      list << node.surface.force_encoding('utf-8') if node.feature.force_encoding('utf-8') =~ /^名詞/
      node = node.next
    end
    list
  end

  def tf(body, noun)
    doc = document_from_body(body)
    doc.count_of(noun).to_f / (doc.nouns.length + 1)
  end

  def idf(body, noun)
    Math.log(10, @documents.length.to_f / (@documents.count{|d| d.has?(noun)} + 1))
  end

  def tfidf(body, noun)
    tf(body, noun) * idf(body, noun)
  end

  class Document
    attr_accessor :body, :nouns

    def has?(noun)
      @nouns.include?(noun)
    end

    def count_of(noun)
      @nouns.count(noun)
    end
  end

end
