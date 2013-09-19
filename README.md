# MONAx
This repository contains the code of the event detection tool used in [this paper](http://www.extractivism.nl/wp-content/uploads/2013/09/derive_2013.pdf).

## Dependencies
You will need the following applications:

* Neo4j
* Full Stanford CoreNLP Suite

You will need the following gems:

* httparty
* stanford-core-nlp (Make sure you copy your copy of CoreNLP to the appropriate folder for this gem, see the gem's installation instructions for details.)
* rjb
* nokogiri
* rdf
* rdf-trig
* uuid
* chronic
* neography

You will need an API key for:

* AlchemyAPI
* TextRazor

## Basic Usage
0. Make sure Neo4j is running.
1. Enter your TextRazor and AlchemyAPI API-keys in the appropriate strings in the `preprocess_text.rb` script.
2. Put all .txt files you wish to process in the same directory as the scripts. Make sure the first line of the .txt file contains the URL of the article, followed by an empty line, followed by the body of the article.
3. Run `preprocess_text.rb`. This will pre-process all `.txt` files in the script's directory and upload the resulting NLP graph to the local Neo4j database.
4. If necessary, edit `process_text.rb` to set the OutputFormatter (of) to a different output format. Supported formats are JSON, Brat Standoff, and RDF TRIG.
4. Run `process_text.rb`. 

## Support
None. You are on your own. With some Ruby experience, you should be able to get some idea of what is happening and fix any problems you might have.

## Disclaimer
The code for MONAx was written as part of a master thesis project. As a result, the focus was less on code quality, which is now somewhat quite very incredibly awful.
