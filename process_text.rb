require './lib/processor'
require './lib/output_formatter'
require 'neography'
require 'logger'

class OpenStruct
  def to_h
    @table.dup
  end
end

neo4j_instance = Neography::Rest.new
processor = Processor.new(neo4j_instance)
of = OutputFormatter.new

text_files = Dir["./*.txt"]
text_files.each do |text_file|
	filename = text_file.match(/([0-9]+)\.txt/)[1]
	text_url = IO.readlines(text_file)[0].strip
	processed = processor.process(text_url)
	events = processed[:outlist]
	events = processor.process(text_url)
	json = of.json(events)
	File.open("#{filename}.json", 'w'){ |file| file.write(json) }
end