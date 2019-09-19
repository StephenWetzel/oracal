#! /usr/bin/env ruby

require 'nokogiri'
require 'open-uri'
require 'openssl'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

MIN_SENTENCE_LENGTH = 50
MIN_LETTER_RATIO = 0.9
MAX_SPACE_RATIO = 0.5
MIN_SENTENCES = 3

def get_sentence_from_url(url)
  puts "Going to #{url}"
  begin
    doc = Nokogiri::HTML(open(url))
    text = doc.search('//text()').map(&:text).delete_if{|x| x !~ /\w/}
    text.sort_by(&:length).reverse.each do |block|
    # text.shuffle.each do |block|
      # puts "Testing block #{block}"
      next unless good_sentence?(block)
      sentence = sentence_from_block(block)
      return sentence unless sentence.nil?
    end
    return nil
  rescue OpenURI::HTTPError => e
    puts e.message
    return nil
  end
end

def sentence_from_block(block)
  sentences = block.split(/(?<=[?.!])/).shuffle
  puts "Choosing sentence from #{sentences}"
  sentences.each do |sentence|
    return sentence if good_sentence?(sentence)
  end
  return nil
end

def good_sentence?(sentence)
  return sentence.length > MIN_SENTENCE_LENGTH && letter_ratio(sentence) > MIN_LETTER_RATIO && space_ratio(sentence) < MAX_SPACE_RATIO
end

def letter_ratio(block)
  return block.scan(/[a-zA-Z ]/).count.to_f / block.length
end

def space_ratio(block)
  return block.scan(/\s/).count.to_f / block.length
end

def convert_search_settings(search_settings)
  query_params = ''
  search_settings.each {|k, v| query_params += "&#{k}=#{v}"}
  return query_params
end



# query = 'what kind of bread to use for french toast'
puts "What do you want to know? "
query = gets.chomp

search_settings = {kp: '-2', kz: '-1', kc: '-1', kav: '-1', kaf: '1', kd: '-1'}
sentences = []

search_url = "https://duckduckgo.com/html?q=#{query}"
search_url += convert_search_settings(search_settings)

puts "Searching #{search_url}"

search_results = Nokogiri::HTML(open(search_url))
search_results.css("a[class=result__a]").to_a.shuffle.each do |result|
  sentence = get_sentence_from_url(result['href'])
  sentences.push(sentence) unless sentence.nil?
  puts sentence
  break if sentences.length > MIN_SENTENCES && rand > 0.7
end


puts "\n\n#{query}"
puts "The Oracal says:\n\n"
puts sentences.join(' ')


