require 'httparty'

class AlchemyAPI
	include HTTParty
	base_uri 'access.alchemyapi.com/calls'
	
	def initialize(k)
		@key = k
	end
	
	def get_author_url(u)
		options = { :query => { :apikey => @key, :url => u, :outputMode => 'json' } }
		self.class.get('/url/URLGetAuthor', options)
	end
	
	def get_author_html(h)
		options = { :query => { :apikey => @key, :html => h, :outputMode => 'json' } }
		self.class.get('/html/HTMLGetAuthor', options)
	end
	
	def get_text_url(u)
		options = { :query => { :apikey => @key, :url => u, :outputMode => 'json' } }
		self.class.get('/url/URLGetText', options)
	end
	
	def get_text_html(h)
		options = { :query => { :apikey => @key, :html => h, :outputMode => 'json' } }
		self.class.get('/html/HTMLGetText', options)
	end
end