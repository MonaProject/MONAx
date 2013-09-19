require 'open-uri'
require 'nokogiri'
require 'time'
require 'chronic'

class PubDateFinder
	def initialize
		#
	end
	
	def get_and_parse_html(url)
		html = open(url) {|f| f.read }
		return Nokogiri::HTML(html)
	end
	
	def get_time_element_strings(parsed_html)
		time_elements = parsed_html.xpath("//time")
		time_element_strings = []
		time_elements.each do |element|
			time_element_strings << element.text
			element.attributes.each do |attribute|
				time_element_strings << attribute[1].to_s
			end
		end
		return time_element_strings
	end
	
	def get_meta_element_strings(parsed_html)
		meta_date_keywords = ['publi', 'create', 'issue']
		
		meta_elements = []
		meta_date_keywords.each do |kw|
			# Look at this nice xpath selector. Isn't being forced to use xpath 1.0 great? Screw you, Nokogiri.				
			meta_elements += parsed_html.xpath("//meta[contains(translate(@name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), '#{kw}')]")
			meta_elements += parsed_html.xpath("//meta[contains(translate(@property, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), '#{kw}')]")
			meta_elements += parsed_html.xpath("//meta[contains(translate(@itemprop, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), '#{kw}')]")
		end
		
		meta_element_strings = []
		meta_elements.each do |element|
			meta_element_strings << element['content'].to_s
		end
		return meta_element_strings
	end
	
	def parse_for_dates(str)
		begin
			time_parse = Time.parse(str)
		rescue ArgumentError
			time_parse = nil
		end
		chronic_parse = Chronic.parse(str)
		return time_parse || chronic_parse
	end
	
	def most_common_date(a)
	  a.group_by do |e|
	    e.strftime("%Y-%m-%d") 
	  end.values.max_by(&:size).first
	end
	
	def get_date_url(url)
		url_time = parse_for_dates(url)
		if url_time != nil
			return url_time
		end
		
		parsed_html = get_and_parse_html(url)
		
		time_strings = get_time_element_strings(parsed_html)
		parsed_dates = []
		time_strings.each do |str|
			parsed_dates << parse_for_dates(str)
		end
		parsed_dates.reject!{ |str| str == nil }
		most_common_time = most_common_date(parsed_dates) unless parsed_dates.count == 0

		meta_strings = get_meta_element_strings(parsed_html)
		parsed_dates = []
		meta_strings.each do |str|
			parsed_dates << parse_for_dates(str)
		end
		parsed_dates.reject!{ |str| str == nil }
		most_common_meta = most_common_date(parsed_dates) unless parsed_dates.count == 0
		
		return most_common_time || most_common_meta
	end
end