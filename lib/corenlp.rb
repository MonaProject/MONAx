require 'stanford-core-nlp'

class CoreNLP
	def initialize
		StanfordCoreNLP.set_model('ner.model', 'muc.7class.distsim.crf.ser.gz')
		StanfordCoreNLP.jvm_args = ['-Xms1024M', '-Xmx4096M']
		@corenlp_pipeline = StanfordCoreNLP.load(:tokenize, :ssplit, :pos, :lemma, :parse, :ner, :dcoref)
	end
	
	def rubyize(text)
		sentences = []
		text.get(:sentences).to_a.each_with_index do |sentence, index|
			tokens = []
			dependencies = []
			
			sentence.get(:tokens).to_a.each do |token|
				tokhash = {
					:index => token.get(:index).to_s.to_i,
					:begin => token.get(:character_offset_begin).to_s.to_i,
					:end => token.get(:character_offset_end).to_s.to_i,
					:text => token.get(:original_text).to_s,
					:lemma => token.get(:lemma).to_s,
					:pos => token.get(:part_of_speech).to_s
				}
				
				if token.get(:stem)
					tokhash[:stem] = token.get(:stem).to_s
				end
				
				if token.get(:named_entity_tag).to_s != 'O'
					tokhash[:corenlp_types] = [token.get(:named_entity_tag).to_s]
				end
				
				if token.get(:normalized_named_entity_tag)
					tokhash[:normalized_ner] = token.get(:normalized_named_entity_tag).to_s
				end
				
				if token.get(:timex)
					tokhash[:timex] = token.get(:timex).to_s
				end
				
				tokens << tokhash
			end
			
			sentence.get(:collapsed_cC_processed_dependencies).typedDependencies.to_a.each do |dependency|
				dependencies << {
					:type => dependency.reln.to_s,
					:governor => dependency.gov.index.to_i,
					:dependent => dependency.dep.index.to_i,
				}
			end
			
			sentences << {:index => index+1, :tokens => tokens, :dependencies => dependencies}
		end
		return sentences
	end
	
	def process(text, creation_date)
		text = StanfordCoreNLP::Annotation.new(text)
		
		# Le dirty hack to set a reference date for SUTime.
		docdate_annotation = Rjb::import('edu.stanford.nlp.ling.CoreAnnotations$DocDateAnnotation')
		text._invoke('set', 'Ljava.lang.Class;Ljava.lang.Object;', docdate_annotation, creation_date)
		
		@corenlp_pipeline.annotate(text)
		return rubyize(text)
	end
end