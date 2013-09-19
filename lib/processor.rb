require 'net/http'

class Processor
	def initialize(neo4j_instance)
		@neo4j = neo4j_instance
		@neo4j_uri = URI('http://localhost:7474/db/data/cypher')
		@dbpedia_actortypes = ["Organization", "Organisation", "Person"]
		@dbpedia_placetypes = ["Place"]
		@freebase_actortypes = ["/organization/australian_organization", "/organization/club", "/organization/club_interest", "/organization/endowed_organization", "/organization/membership_organization", "/organization/non_profit_designation", "/organization/non_profit_organization", "/organization/organization", "/organization/organization_committee", "/organization/organization_committee_title", "/organization/organization_founder", "/organization/organization_member", "/organization/organization_partnership", "/organization/organization_scope", "/organization/organization_sector", "/organization/organization_type", "/organization/role", "/people/american_indian_group", "/people/appointed_role", "/people/appointee", "/people/appointer", "/people/canadian_aboriginal_group", "/people/cause_of_death", "/people/chinese_ethnic_group", "/people/deceased_person", "/people/ethnicity", "/people/family", "/people/family_member", "/people/family_name", "/people/gender", "/people/marriage_union_type", "/people/measured_body_part", "/people/measured_person", "/people/person", "/people/place_of_interment", "/people/profession", "/people/professional_field", "/people/wedding_venue"]
		@freebase_placetypes = ["/location/administrative_division", "/location/ar_department", "/location/ar_province", "/location/australian_external_territory", "/location/australian_local_government_area", "/location/australian_state", "/location/australian_suburb", "/location/australian_territory", "/location/br_federal_district", "/location/br_state", "/location/ca_census_division", "/location/ca_indian_reserve", "/location/ca_territory", "/location/cemetery", "/location/census_designated_place", "/location/citytown", "/location/cn_autonomous_county", "/location/cn_autonomous_prefecture", "/location/cn_autonomous_region", "/location/cn_city_district", "/location/cn_county", "/location/cn_county_level_city", "/location/cn_municipality", "/location/cn_prefecture", "/location/cn_prefecture_level_city", "/location/cn_province", "/location/cn_special_administrative_region", "/location/continent", "/location/country", "/location/dated_location", "/location/de_borough", "/location/de_city", "/location/de_regierungsbezirk", "/location/de_rural_district", "/location/de_state", "/location/de_urban_district", "/location/es_autonomous_city", "/location/es_autonomous_community", "/location/es_comarca", "/location/es_place_of_sovereignty", "/location/es_province", "/location/fr_department", "/location/fr_region", "/location/geometry", "/location/hk_district", "/location/hud_county_place", "/location/hud_foreclosure_area", "/location/id_city", "/location/id_province", "/location/id_regency", "/location/id_subdistrict", "/location/in_city", "/location/in_district", "/location/in_division", "/location/in_state", "/location/in_union_territory", "/location/irish_province", "/location/it_comune", "/location/it_frazione", "/location/it_province", "/location/it_region", "/location/jp_city_town", "/location/jp_designated_city", "/location/jp_district", "/location/jp_prefecture", "/location/jp_special_ward", "/location/jp_subprefecture", "/location/kp_city", "/location/kp_county", "/location/kp_metropolitan_city", "/location/kp_special_city", "/location/location", "/location/mailing_address", "/location/mx_federal_district", "/location/mx_federal_district_borough", "/location/mx_municipality", "/location/mx_state", "/location/my_district", "/location/my_division", "/location/my_federal_territory", "/location/my_state", "/location/neighborhood", "/location/nl_municipality", "/location/nl_province", "/location/offical_symbol_variety", "/location/place_with_neighborhoods", "/location/postal_code", "/location/pr_municipality", "/location/province", "/location/region", "/location/ru_autonomous_oblast", "/location/ru_autonomous_okrug", "/location/ru_federal_city", "/location/ru_federal_district", "/location/ru_krai", "/location/ru_oblast", "/location/ru_raion", "/location/ru_republic", "/location/statistical_region", "/location/symbol_of_administrative_division", "/location/tr_region", "/location/tw_direct_controlled_municipality", "/location/tw_district", "/location/tw_province", "/location/tw_provincial_city", "/location/tw_township", "/location/ua_autonomous_republic", "/location/ua_oblast", "/location/ua_raion", "/location/uk_civil_parish", "/location/uk_constituent_country", "/location/uk_council_area", "/location/uk_crown_dependency", "/location/uk_district", "/location/uk_london_borough", "/location/uk_metropolitan_borough", "/location/uk_metropolitan_county", "/location/uk_non_metropolitan_county", "/location/uk_non_metropolitan_district", "/location/uk_overseas_territory", "/location/uk_principal_area", "/location/uk_region", "/location/uk_statistical_location", "/location/uk_unitary_authority", "/location/us_cbsa", "/location/us_county", "/location/us_federal_district", "/location/us_indian_reservation", "/location/us_state", "/location/us_territory", "/location/vn_centrally_controlled_municipality", "/location/vn_provincial_city", "/location/vn_township", "/location/vn_urban_district"]
		@corenlp_actortypes = ["ORGANIZATION", "PERSON"]
		@corenlp_placetypes = ["LOCATION"]
	end
	
	def neo4j_query(querystring)
		# Le dirty hack method to circumvent the weird errors that the neo4j query wrapper gives at seemingly random intervals.
		tokens = JSON.load(Net::HTTP.post_form(@neo4j_uri, 'query' => querystring).body)['data']
		return tokens.map{|token| 
      $logger.debug "Loading token #{token[0]['self']}"
      Neography::Node.load(token[0]['self'])}
	end
	
	def document_node(url)		
		document = neo4j_query("START root = node(0) MATCH root-[:document]->document WHERE document.url = '%s' RETURN document" % url)
		return document.first
	end
	
	def sentence_nodes(document_node)		
		sentences = neo4j_query("START document = node(%s) MATCH document-[:sentence]->sentence RETURN sentence" % document_node.neo_id.to_i)
		return sentences
	end
	
	def token_nodes(sentence_node)		
		tokens = neo4j_query("START sentence = node(%s) MATCH sentence-[:token]->token RETURN token" % sentence_node.neo_id.to_i)
		return tokens
	end
	
	def dependent_typed_tokens(token_node)
		typed_freebase = neo4j_query("START verb = node(%s) MATCH verb-[:dependency*]->dependent WHERE has(dependent.freebase_types) RETURN dependent" % token_node.neo_id.to_i)
		typed_dbpedia = neo4j_query("START verb = node(%s) MATCH verb-[:dependency*]->dependent WHERE has(dependent.dbpedia_types) RETURN dependent" % token_node.neo_id.to_i)
		typed_corenlp = neo4j_query("START verb = node(%s) MATCH verb-[:dependency*]->dependent WHERE has(dependent.corenlp_types) RETURN dependent" % token_node.neo_id.to_i)
		typed_timex = neo4j_query("START verb = node(%s) MATCH verb-[:dependency*]->dependent WHERE has(dependent.timex) RETURN dependent" % token_node.neo_id.to_i)
		
		typed = typed_freebase + typed_dbpedia + typed_corenlp + typed_timex
		return typed.uniq
	end
	
	def typed_token_sequences(token_nodes)
		#
	end
	
	def process(text_url)
		outhash = {}
		outhash[:outlist] = []
		docnode = document_node(text_url)
		outhash[:docnode] = docnode.to_h
		sentnodes = sentence_nodes(docnode)
		sentnodes.each do |sentnode|
			toknodes = token_nodes(sentnode)
			verbnodes = toknodes.select { |token| token['pos'].start_with?('V') }
			verbnodes.each do |verbnode|
        $logger.debug "Verb Node #{verbnode.inspect}. Hash: #{verbnode.to_h.inspect}"
				typednodes = dependent_typed_tokens(verbnode)
				if not typednodes.empty?
					event = {:event => verbnode.to_h, :actors => [], :places => [], :times => []}
					typednodes.each do |typednode|
            $logger.debug "Typed Node #{typednode.inspect}"
						
						if typednode[:timex]
							event[:times] << typednode.to_h
						end
						
						if typednode[:corenlp_types]
							if not (typednode[:corenlp_types] & @corenlp_actortypes).empty?
								event[:actors] << typednode.to_h
							end
							
							if not (typednode[:corenlp_types] & @corenlp_placetypes).empty?
								event[:places] << typednode.to_h
							end
						end
						
						if typednode[:dbpedia_types]
							if not (typednode[:dbpedia_types] & @dbpedia_actortypes).empty?
								event[:actors] << typednode.to_h
							end
						
							if not (typednode[:dbpedia_types] & @dbpedia_placetypes).empty?
								event[:places] << typednode.to_h
							end
						end
						
						if typednode[:freebase_types]
							if not (typednode[:freebase_types] & @freebase_actortypes).empty?
								event[:actors] << typednode.to_h
							end
							
							if not (typednode[:freebase_types] & @freebase_placetypes).empty?
								event[:places] << typednode.to_h
							end
						end
					end
					event[:actors].uniq!
					event[:places].uniq!
					event[:times].uniq!
					
					if not (event[:actors].empty? and event[:places].empty? and event[:times].empty?)
						outhash[:outlist] << event
					end
				end
			end
		end
		return outhash
	end
end