require 'httparty'

class TextRazor
	include HTTParty
	base_uri 'http://api.textrazor.com/'
	
	def initialize(k)
		@key = k
	end
	
	def post(text, extractors)
		options = { :body => { :apiKey => @key, :text => text, :extractors => extractors } }
		self.class.post('', options)
	end
end