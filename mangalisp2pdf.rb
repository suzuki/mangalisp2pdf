#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'rubygems'
require 'prawn'
require 'nokogiri'
require 'open-uri'

base_uri = 'http://lambda.bugyo.tk/cdr/mwl/'
pdf_file = 'manga_lisp.pdf'
pdf_font = 'umefont_422/ume-ugo5.ttf'

# get all section page data
doc = Nokogiri(open(base_uri).read)

sections = Array.new

tables = doc.xpath('//table')
trs = tables[0].xpath('tr')
trs.each do |tr|
  link  = tr.xpath('td[1]').xpath('a').attribute('href').to_s
  name  = tr.xpath('td[1]').inner_text
  title = tr.xpath('td[2]').inner_text

  sections << { 'link' => link, 'name' => name, 'title' => title }
end

sections.each do |section|
  images = Array.new

  doc = Nokogiri(open(base_uri + section['link']).read)

  /(http:.+\/)[^\/]+\.html/ =~ base_uri + section['link']
  section_base_uri = $1

  doc.xpath('//img').each do |img|
    images << section_base_uri + img.attribute('src').to_s
  end

  section['images'] = images
end


# create PDF
pdf = Prawn::Document.new(:page_size => [480,640],
                          :left_margin => 0,
                          :top_margin => 0,
                          :bottom_margin =>0)

pdf.font pdf_font

pdf.bounding_box([40,400], :width => 400, :height => 200) do
  pdf.text "マンガで分かるLisp\n(Manga Guide to Lisp)", :size => 32
end

sections.each do |section|
  pdf.start_new_page

  pdf.bounding_box([40,400], :width => 400, :height => 200) do
    /([^(]+)(\(.+\))/ =~ section['title']
    title = $1 + "\n" + $2
    pdf.text title, :size => 24
  end

  section['images'].each do |image|
    pdf.start_new_page
    pdf.image open(image), :at => [0,640], :width => 480, :height => 640
  end

end

pdf.render_file pdf_file
