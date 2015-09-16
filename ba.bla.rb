#! /usr/bin/env ruby
require 'nokogiri'
require 'open-uri'

def print_title(title)
  puts "\033[0;1;37m#{title.upcase}\033[0m\n\n"
end

def print_header(header)
  if header.nil? then
    puts ""
  else
    lang = header.children.first.attr('class').split.map{ |x| (x.start_with? 'babFlag-') ? x[8..-1] : nil}.compact.join
    puts "  \033[0;1;32m[#{lang.upcase}]\033[0m \033[0;1;37m#{header.text}\033[0m\n\n"
  end
end

def print_hr(indent, width, pattern = '- ')
  puts " "*indent + (pattern*((width+pattern.size-1)/pattern.size))[0,width]
  
  
end
# allow *sdadd* for bold
def split_in_rows(text, width)
  rows = []
  line = ["\033[0;45m "]
  length = 0
  bold = false
  
  text.chars.each do |char|
    if char == '*' then
      if bold == true then
        line.push "\033[0;45m"
      else
        line.push "\033[1;36m"
      end
      
      bold = !bold
    else
      if char != "\n" then
        line.push char
        length += 1
      end
      if length == width or char == "\n" then
        line.push " "*(width-length) + " \033[0m"
        rows.push line.join
        line = []
        line.push "\033[0;45m "
        line.push "\033[1;37m" if bold
        length = 0
      end
    end
  end
 
  if length > 0 then
#    line.push "\033[0m" if bold
    rows.push(line.join + " "*(width-length+1) + "\033[0m")
  end
 
  rows
end

def print_in_columns(indent, left_txt, left_width, space, right_txt, right_width)
  left = split_in_rows(left_txt, left_width)
  left_blank = "\033[0;45m"+" "*(left_width+2) + "\033[0m"
  right = split_in_rows(right_txt, right_width)
  right_blank = "\033[0;45m"+" "*(right_width+2)+"\033[0m"
  
  for i in 0..([left.size, right.size].min)
    line = " "*indent + (left[i]||left_blank) + " "*space + (right[i]||right_blank)
    puts line    
  end
end

def print_results(results)
  results.css('div.result-wrapper').each do |result|
    left = []
    right = []
    
    x = result.css('div.row-fluid.result-row').each do |row|
      left.push(Nokogiri::HTML(row.css('.result-left')[0].inner_html.gsub('<strong>','*').gsub('</strong>','*')).text.strip)
      right.push(Nokogiri::HTML(row.css('.result-right')[0].inner_html.gsub('<strong>','*').gsub('</strong>','*')).text.strip)
    end

    print_in_columns(4, left.join("\n"), 50, 1, right.join("\n"), 50)
    puts
    #print_hr(4, 82)
  end 
end

langs = {
  'pl' => 'polski',
  'en' => 'angielski',
}

lang = ARGV[0].split '/'
from = langs[lang[0]] || lang[0]
to = langs[lang[1]] || lang[1]

query = ARGV[1..-1].join('-').gsub(' ','-')

url = "http://pl.bab.la/dictionary/#{from}-#{to}/#{query}"

doc = Nokogiri::HTML(open(url))

doc.css('section').each do |section|
  title = section.css('h2.section-block-head').first
  if title then
    txt = title.text
    if txt.include? "tłumaczenie" then
      print_title(txt)

      
      section.css('div.result-block').each do |result|
        header = result
        while !header.nil? and header.name != 'h3' do
          header = header.previous       
        end
        
        print_header(header)

        print_results(result)
      end 
    
    end
    
  
  end
  #puts section
end