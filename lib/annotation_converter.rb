require 'json'

class AnnotationConverter
	def initialize
		#
	end
	
	def convert(annotation_file)
		t_list = []
		r_list = []
	
		lines = IO.readlines(annotation_file)
		lines.each do |line|
		
			if line.start_with?("T")
			
				line_split = line.split("\t")
				annotation_id = line_split[0]
				annotation_text = line_split[2].strip
		
				annotation = line_split[1]
				annotation_split = annotation.split(" ")
				annotation_type = annotation_split[0]
				annotation_begin = annotation_split[1]
				annotation_end = annotation_split[2]
			
				t_list << {:id => annotation_id, :text => annotation_text, :type => annotation_type, :begin => annotation_begin, :end => annotation_end}
			
			elsif line.start_with?("R")
			
				line_split = line.split("\t")
				relation_id = line_split[0]
			
				relation = line_split[1]
				relation_split = relation.split(" ")
				relation_type = relation_split[0]
				relation_left = relation_split[1].split(":")[1]
				relation_right = relation_split[2].split(":")[1]
			
				r_list << {:id => relation_id, :type => relation_type, :left => relation_left, :right => relation_right}
			end
		end
	
		outlist = []
	
		events = t_list.select{|t| t[:type] == 'Event'}
		
		events.each do |event|
			
			eventhash = {:event => {:text => event[:text], :begin => event[:begin], :end => event[:end]}, :actors => [], :times => [], :places => []}				
			related = r_list.select{|r| r[:left] == event[:id]}
		
			related.each do |related|
				annotation = t_list.select{|t| t[:id] == related[:right]}.first
			
				if annotation[:type] == 'Actor'
					eventhash[:actors] << {:text => annotation[:text], :begin => annotation[:begin], :end => annotation[:end]}
				end
			
				if annotation[:type] == 'Place'
					eventhash[:places] << {:text => annotation[:text], :begin => annotation[:begin], :end => annotation[:end]}
				end
			
				if annotation[:type] == 'Time'
					eventhash[:times] << {:text => annotation[:text], :begin => annotation[:begin], :end => annotation[:end]}
				end
			
			end
		
			outlist << eventhash
		
		end
		return outlist.to_json
	end
end