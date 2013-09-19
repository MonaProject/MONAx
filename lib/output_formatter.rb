require 'json'
require 'rdf'
require 'rdf/trig'
require 'rdf/turtle'
require 'uuid'

class OutputFormatter
	def initialize
		@uuid = UUID.new
	end

	include RDF

	def rdf(events, docnode)
		all_graphs = []

		str = RDF::Vocabulary.new("http://nlp2rdf.lod2.eu/schema/string/")
		sem = RDF::Vocabulary.new("http://semanticweb.cs.vu.nl/2009/11/sem/")
		gaf = RDF::Vocabulary.new("http://groundedannotationframework.org/")
		mona = RDF::Vocabulary.new("http://semanticweb.cs.vu.nl/2013/06/mona/")
		skos = RDF::Vocabulary.new("http://www.w3.org/2004/02/skos/core#")
		dbpedia = RDF::Vocabulary.new("http://dbpedia.org/ontology/")

		event_mentions_to_strings_node = RDF::URI.new(mona["event_mentions_to_strings"])
		event_mentions_to_strings = RDF::Graph.new(event_mentions_to_strings_node)

		event_instances_to_event_mentions_node = RDF::URI.new(mona["event_instances_to_event_mentions"])
		event_instances_to_event_mentions = RDF::Graph.new(event_instances_to_event_mentions_node)

		sem_events_to_event_instances_node = RDF::URI.new(mona["sem_events_to_event_instances"])
		sem_events_to_event_instances = RDF::Graph.new(sem_events_to_event_instances_node)

		actor_mentions_to_strings_node = RDF::URI.new(mona["actor_mentions_to_strings"])
		actor_mentions_to_strings = RDF::Graph.new(actor_mentions_to_strings_node)

		actor_instances_to_actor_mentions_node = RDF::URI.new(mona["actor_instances_to_actor_mentions"])
		actor_instances_to_actor_mentions = RDF::Graph.new(actor_instances_to_actor_mentions_node)

		sem_actors_to_actor_instances_node = RDF::URI.new(mona["sem_actors_to_actor_instances"])
		sem_actors_to_actor_instances = RDF::Graph.new(sem_actors_to_actor_instances_node)

		place_mentions_to_strings_node = RDF::URI.new(mona["place_mentions_to_strings"])
		place_mentions_to_strings = RDF::Graph.new(place_mentions_to_strings_node)

		place_instances_to_place_mentions_node = RDF::URI.new(mona["place_instances_to_place_mentions"])
		place_instances_to_place_mentions = RDF::Graph.new(place_instances_to_place_mentions_node)

		sem_places_to_place_instances_node = RDF::URI.new(mona["sem_places_to_place_instances"])
		sem_places_to_place_instances = RDF::Graph.new(sem_places_to_place_instances_node)

		time_mentions_to_strings_node = RDF::URI.new(mona["time_mentions_to_strings"])
		time_mentions_to_strings = RDF::Graph.new(time_mentions_to_strings_node)

		time_instances_to_time_mentions_node = RDF::URI.new(mona["time_instances_to_time_mentions"])
		time_instances_to_time_mentions = RDF::Graph.new(time_instances_to_time_mentions_node)

		sem_times_to_time_instances_node = RDF::URI.new(mona["sem_times_to_time_instances"])
		sem_times_to_time_instances = RDF::Graph.new(sem_times_to_time_instances_node)

		sem_times_to_normalized_times_node = RDF::URI.new(mona["sem_times_to_normalized_times"])
		sem_times_to_normalized_times = RDF::Graph.new(sem_times_to_normalized_times_node)

		sem_relationships_node = RDF::URI.new(mona["sem_relationships"])
		sem_relationships = RDF::Graph.new(sem_relationships_node)
		
		provenance = RDF::Graph.new(RDF::URI.new(mona["provenance"]))

		events.each do |event|

			event_mention_node = RDF::URI.new(mona["MENTION_#{@uuid.generate}"])

			event_anchor_text = RDF::Literal.new(event[:event][:text], :language => :en)
			event_mentions_to_strings << [event_mention_node, str.anchorOf, event_anchor_text]

			event_instance_node = RDF::URI.new(mona["INSTANCE_#{@uuid.generate}"])
			event_instances_to_event_mentions << [event_instance_node, gaf.denotedBy, event_mention_node]

			sem_events_to_event_instances << [event_instance_node, RDF.type, sem.Event]
			sem_events_to_event_instances << [event_instance_node, RDFS.label, event[:event][:lemma]]

			provenance << [event_mentions_to_strings_node, gaf.derivedFrom, "Stanford POS Tagger"]
			provenance << [actor_mentions_to_strings_node, gaf.derivedFrom, "TextRazor API"]
			provenance << [place_mentions_to_strings_node, gaf.derivedFrom, "TextRazor API"]
			provenance << [time_mentions_to_strings_node, gaf.derivedFrom, "Stanford NER"]
			provenance << [sem_times_to_normalized_times_node, gaf.derivedFrom, "Stanford SUTime"]
			provenance << [sem_relationships_node, gaf.derivedFrom, "Stanford Dependency Parser"]

			provenance << [event_mentions_to_strings_node, sem.accordingTo, docnode[:author]]
			provenance << [actor_mentions_to_strings_node, sem.accordingTo, docnode[:author]]
			provenance << [place_mentions_to_strings_node, sem.accordingTo, docnode[:author]]
			provenance << [time_mentions_to_strings_node, sem.accordingTo, docnode[:author]]

			provenance << [event_mentions_to_strings_node, sem.accordingTo, RDF::URI.new(docnode[:url])]
			provenance << [actor_mentions_to_strings_node, sem.accordingTo, RDF::URI.new(docnode[:url])]
			provenance << [place_mentions_to_strings_node, sem.accordingTo, RDF::URI.new(docnode[:url])]
			provenance << [time_mentions_to_strings_node, sem.accordingTo, RDF::URI.new(docnode[:url])]

			actor_sequences = find_sequences(event[:actors])
			actor_sequences.each do |actor_seq|
				actor_anchor_text = RDF::Literal.new(actor_seq.map{|a| a[:text]}.join(' '), :language => :en)
				
				actor_mention_node = RDF::URI.new(mona["MENTION_#{@uuid.generate}"])
				actor_mentions_to_strings << [actor_mention_node, str.anchorOf, actor_anchor_text]

				actor_instance_node = RDF::URI.new(mona["INSTANCE_#{@uuid.generate}"])
				actor_instances_to_actor_mentions << [actor_instance_node, gaf.denotedBy, actor_mention_node]

				sem_actors_to_actor_instances << [actor_instance_node, RDF.type, sem.Actor]
				sem_actors_to_actor_instances << [actor_instance_node, RDFS.label, actor_anchor_text]

				if actor_seq.first.has_key?(:dbpedia_uri)
					actor_uri = RDF::URI.new(actor_seq.first[:dbpedia_uri])
					sem_actors_to_actor_instances << [actor_instance_node, skos.exactMatch, actor_uri]
				end

				if actor_seq.first.has_key?(:dbpedia_types)
					actor_seq.first[:dbpedia_types].each do |type|
						sem_actors_to_actor_instances << [actor_instance_node, sem.actorType, dbpedia["#{type}"]]
					end
				end

				sem_relationships << [event_instance_node, sem.hasActor, actor_instance_node]
			end

			place_sequences = find_sequences(event[:places])
			place_sequences.each do |place_seq|
				place_anchor_text = RDF::Literal.new(place_seq.map{|a| a[:text]}.join(' '), :language => :en)
				
				place_mention_node = RDF::URI.new(mona["MENTION_#{@uuid.generate}"])
				place_mentions_to_strings << [place_mention_node, str.anchorOf, place_anchor_text]

				place_instance_node = RDF::URI.new(mona["INSTANCE_#{@uuid.generate}"])
				place_instances_to_place_mentions << [place_instance_node, gaf.denotedBy, place_mention_node]

				sem_places_to_place_instances << [place_instance_node, RDF.type, sem.Place]
				sem_places_to_place_instances << [place_instance_node, RDFS.label, place_anchor_text]

				if place_seq.first.has_key?(:dbpedia_uri)
					place_uri = RDF::URI.new(place_seq.first[:dbpedia_uri])
					sem_places_to_place_instances << [place_instance_node, skos.exactMatch, place_uri]
				end

				if place_seq.first.has_key?(:dbpedia_types)
					place_seq.first[:dbpedia_types].each do |type|
						sem_places_to_place_instances << [place_instance_node, sem.placeType, dbpedia["#{type}"]]
					end
				end

				sem_relationships << [event_instance_node, sem.hasPlace, place_instance_node]
			end

			time_sequences = find_sequences(event[:times])
			time_sequences.each do |time_seq|
				time_anchor_text = RDF::Literal.new(time_seq.map{|a| a[:text]}.join(' '), :language => :en)
				
				time_mention_node = RDF::URI.new(mona["MENTION_#{@uuid.generate}"])
				time_mentions_to_strings << [time_mention_node, str.anchorOf, time_anchor_text]

				time_instance_node = RDF::URI.new(mona["INSTANCE_#{@uuid.generate}"])
				time_instances_to_time_mentions << [time_instance_node, gaf.denotedBy, time_mention_node]

				sem_times_to_time_instances << [time_instance_node, RDF.type, sem.Time]
				sem_times_to_time_instances << [time_instance_node, RDFS.label, time_anchor_text]

				if time_seq.first.has_key?(:normalized_ner)
					normalized_time = RDF::Literal.new(time_seq.first[:normalized_ner])
					sem_times_to_normalized_times << [time_instance_node, mona.normalizedTime, normalized_time]
				end

				sem_relationships << [event_instance_node, sem.hasTime, time_instance_node]
			end
		end

		all_graphs << event_mentions_to_strings
		all_graphs << event_instances_to_event_mentions
		all_graphs << sem_events_to_event_instances
		
		all_graphs << actor_mentions_to_strings
		all_graphs << actor_instances_to_actor_mentions
		all_graphs << sem_actors_to_actor_instances

		all_graphs << place_mentions_to_strings
		all_graphs << place_instances_to_place_mentions
		all_graphs << sem_places_to_place_instances

		all_graphs << time_mentions_to_strings
		all_graphs << time_instances_to_time_mentions
		all_graphs << sem_times_to_time_instances

		all_graphs << sem_times_to_normalized_times
		
		all_graphs << sem_relationships

		all_graphs << provenance

		out_string = RDF::TriG::Writer.buffer(
			:prefixes => {
				:rdfs => "http://www.w3.org/2000/01/rdf-schema#",
				:str => "http://nlp2rdf.lod2.eu/schema/string/",
				:mona => "http://semanticweb.cs.vu.nl/2013/06/mona/",
				:gaf => "http://groundedannotationframework.org/",
				:sem => "http://semanticweb.cs.vu.nl/2009/11/sem/",
				:skos => "http://www.w3.org/2004/02/skos/core#",
				:dbpedia => "http://dbpedia.org/ontology/"
			}
		) do |writer| 
			all_graphs.each do |graph|
				writer << graph
			end
		end
	end
	
	def json(events)
		
		outlist = []
		
		events.each do |event|
      $logger.debug "Formatting event #{event.inspect}"
			actor_sequences = find_sequences(event[:actors])
			place_sequences = find_sequences(event[:places])
			time_sequences = find_sequences(event[:times])
			
			new_event = {:event => event[:event], :actors => [], :places => [], :times => []}
			
			time_sequences.each do |sequence|
				sequenced_text = sequence.map{|a| a[:text]}.join(' ')
				sequenced_lemmas = sequence.map{|a| a[:lemma]}
				sequenced_stems = sequence.map{|a| a[:stem]}
				sequenced_indexes = sequence.map{|a| a[:index]}
				
				sequence.last[:lemma] = sequenced_lemmas
				sequence.last[:stem] = sequenced_stems
				sequence.last[:text] = sequenced_text
				sequence.last[:begin] = sequence.first[:begin]
				sequence.last[:end] = sequence.last[:end]
				sequence.last[:index] = sequenced_indexes
				
				new_event[:times] << sequence.last
			end
			
			place_sequences.each do |sequence|
				sequenced_text = sequence.map{|a| a[:text]}.join(' ')
				sequenced_lemmas = sequence.map{|a| a[:lemma]}
				sequenced_stems = sequence.map{|a| a[:stem]}
				sequenced_indexes = sequence.map{|a| a[:index]}
				
				sequence.last[:lemma] = sequenced_lemmas
				sequence.last[:stem] = sequenced_stems
				sequence.last[:text] = sequenced_text
				sequence.last[:begin] = sequence.first[:begin]
				sequence.last[:end] = sequence.last[:end]
				sequence.last[:index] = sequenced_indexes
				
				new_event[:places] << sequence.last
			end
			
			actor_sequences.each do |sequence|
				sequenced_text = sequence.map{|a| a[:text]}.join(' ')
				sequenced_lemmas = sequence.map{|a| a[:lemma]}
				sequenced_stems = sequence.map{|a| a[:stem]}
				sequenced_indexes = sequence.map{|a| a[:index]}
				
				sequence.last[:lemma] = sequenced_lemmas
				sequence.last[:stem] = sequenced_stems
				sequence.last[:text] = sequenced_text
				sequence.last[:begin] = sequence.first[:begin]
				sequence.last[:end] = sequence.last[:end]
				sequence.last[:index] = sequenced_indexes
				
				new_event[:actors] << sequence.last
			end
			
			outlist << new_event
		end
		
		return outlist.to_json
	end
	
	def find_sequences(tokens)
		sequences = []
    $logger.debug "Current tokens: #{tokens.inspect}"
		tokens = tokens.sort_by{|t| t[:index]}
		tokens.each_with_index do |current, index|
			previous = tokens[index-1]
			if previous != nil
				if ((current[:index] - previous[:index]) == 1) and ((current[:freebase_types] == previous[:freebase_types]) or (current[:dbpedia_types] == previous[:dbpedia_types]) or current[:corenlp_types] == previous[:corenlp_types])
					sequences.last << current
				else
					sequences << [current]
				end
			end
		end
		return sequences
	end
	
	def brat_standoff(events)
		t_counter = 1
		r_counter = 1
		outstring = ""
		
		events.each do |event|
			outstring = outstring + "T#{t_counter}\tEvent #{event[:event][:begin]} #{event[:event][:end]}\t#{event[:event][:text]}\n"
			event_annotation = "T#{t_counter}"
			t_counter += 1
			
			actor_annotations = []
			find_sequences(event[:actors]).each do |actor|
				outstring = outstring + "T#{t_counter}\tActor #{actor.first[:begin]} #{actor.last[:end]}\t#{actor.map{|a| a[:text]}.join(' ')}\n"
				actor_annotations << "T#{t_counter}"
				t_counter += 1
			end
			
			location_annotations = []
			find_sequences(event[:places]).each do |location|
				outstring = outstring + "T#{t_counter}\tPlace #{location.first[:begin]} #{location.last[:end]}\t#{location.map{|a| a[:text]}.join(' ')}\n"
				location_annotations << "T#{t_counter}"
				t_counter += 1
			end
			
			times_annotations = []
			find_sequences(event[:times]).each do |time|
				outstring = outstring + "T#{t_counter}\tTime #{time.first[:begin]} #{time.last[:end]}\t#{time.map{|a| a[:text]}.join(' ')}\n"
				times_annotations << "T#{t_counter}"
				t_counter += 1
			end
			
			actor_annotations.each do |actor_annotation|
				outstring = outstring + "R#{r_counter}\thasActor Arg1:#{event_annotation} Arg2:#{actor_annotation}\n"
				r_counter += 1
			end
			
			location_annotations.each do |location_annotation|
				outstring = outstring + "R#{r_counter}\thasPlace Arg1:#{event_annotation} Arg2:#{location_annotation}\n"
				r_counter += 1
			end
			
			times_annotations.each do |time_annotation|
				outstring = outstring + "R#{r_counter}\thasTime Arg1:#{event_annotation} Arg2:#{time_annotation}\n"
				r_counter += 1
			end
		end
		return outstring
	end
end