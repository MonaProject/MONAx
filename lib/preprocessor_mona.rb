require_relative 'pubdatefinder'
require_relative 'alchemyapi'
require_relative 'textrazor'
require_relative 'corenlp'

class PreProcessor
	def initialize(alchemyapi_key, textrazor_key, neo4j_instance)
		@alchemyapi = AlchemyAPI.new(alchemyapi_key)
		@textrazor = TextRazor.new(textrazor_key)
		@pubdatefinder = PubDateFinder.new
		@corenlp = CoreNLP.new
		@neo4j = neo4j_instance
	end
	
	def merge_textrazor_words_entities(text_textrazor)
		words = text_textrazor['sentences'].map{|s| s['words']}.flatten
		entities = text_textrazor['entities']
		words.each do |word|
			nerhash = entities.select{|e| e['matchingTokens'].include?(word['position'])}.first
			if nerhash
				if nerhash.has_key?('type') && nerhash['type'].size != 0
					word[:dbpedia_types] = nerhash['type']
				end
				if nerhash.has_key?('freebaseTypes') && nerhash['freebaseTypes'].size != 0
					word[:freebase_types] = nerhash['freebaseTypes']
				end
				if nerhash.has_key?('freebaseId') && nerhash['freebaseId'].size != 0
					word[:freebase_uri] = "http://freebase.com" + nerhash['freebaseId']
				end
				if nerhash.has_key?('wikiLink') && nerhash['wikiLink'].size != 0
					word[:dbpedia_uri] = nerhash['wikiLink'].sub("http://en.wikipedia.org/wiki/","http://dbpedia.org/resource/")
				end
			end		
		end
		return text_textrazor
	end
	
	def merge_textrazor_corenlp(text_textrazor, text_corenlp)
		corenlp_words = text_corenlp.map{|s| s[:tokens]}.flatten
		textrazor_words = text_textrazor['sentences'].map{|s| s['words']}.flatten
		corenlp_words.each do |corenlp_word|
			textrazor_token = textrazor_words.select{|t| (t['startingPos'] >= corenlp_word[:begin]) and (t['endingPos'] <= corenlp_word[:end])}.first
			if textrazor_token
				corenlp_word[:stem] = textrazor_token['stem'] unless not textrazor_token['stem']
				corenlp_word[:dbpedia_types] = textrazor_token[:dbpedia_types] unless not textrazor_token[:dbpedia_types]
				corenlp_word[:freebase_types] = textrazor_token[:freebase_types] unless not textrazor_token[:freebase_types]
				corenlp_word[:dbpedia_uri] = textrazor_token[:dbpedia_uri] unless not textrazor_token[:dbpedia_uri]
				corenlp_word[:freebase_uri] = textrazor_token[:freebase_uri] unless not textrazor_token[:freebase_uri]
			end
		end
		return text_corenlp
	end
	
	def store(text_url, merged_text, text_date, text_author, text_body)
		ref_node = Neography::Node.load(Neography.ref_node)
		document_node = Neography::Node.create(:url => text_url, :author => text_author, :date => text_date, :text => text_body)
		ref_node.outgoing(:document) << document_node
		
		merged_text.each_with_index do |sentence, index|
			tokens = sentence[:tokens]
			dependencies = sentence[:dependencies]
			
			sentence_node = Neography::Node.create(:index => sentence[:index])
			document_node.outgoing(:sentence) << sentence_node
			
			token_index_to_node = {}
			tokens.each do |token|
				token_node = Neography::Node.create(token)
				token_index_to_node[token[:index]] = token_node
				Neography::Relationship.create(:token, sentence_node, token_node)
			end
			
			dependencies.each do |dependency|
				governor = token_index_to_node[dependency[:governor]]
				dependent = token_index_to_node[dependency[:dependent]]
				Neography::Relationship.create(:dependency, governor, dependent, :dependency => dependency[:type])
			end	
		end
	end
	
	def preprocess(text_url, text_body)
		text_date = @pubdatefinder.get_date_url(text_url)
		text_author = @alchemyapi.get_author_url(text_url)['author']
		text_corenlp = @corenlp.process(text_body, text_date.strftime("%Y-%m-%d"))
		
		text_textrazor = @textrazor.post(text_body, 'entities,words,dependency-trees').parsed_response['response']		
		text_textrazor = merge_textrazor_words_entities(text_textrazor)
		text_merged = merge_textrazor_corenlp(text_textrazor, text_corenlp)
		
		store(text_url, text_merged, text_date, text_author, text_body)
	end
end