require './lib/preprocessor_mona'
require 'neography'
require 'logger'

alchemyapi_key = ''
textrazor_key = ''
neo4j_instance = Neography::Rest.new

preprocessor = PreProcessor.new(alchemyapi_key, textrazor_key, neo4j_instance)

text_files = Dir["./*.txt"]

text_files.each do |text_file|
	text_url = IO.readlines(text_file)[0].strip
	text_body = File.read(text_file) 
	preprocessor.preprocess(text_url, text_body)
  exit
end