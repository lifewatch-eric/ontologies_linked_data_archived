Bubastis version 1.1 
6th November 2009
---

Bubastis is an ontology change tool which is able to analyse two ontologies (typically two versions of the same ontology) to highlight logical change which have occurred and to present these changes in more or less detail, as required.


Usage:
java -jar bubastis.jar parameters:
(required)  -1 location of ontology 1 (note this is a URI so if it's a local file you need to specify this with file:/c/:file_name.owl, otherwise it will attempt to read the location from the web)
(required)  -2 location_of_ontology_2 (note this is also a URI )
(optional)  -t location of output file to send results, default is to console
(optional)  -s produce a summary version of results (short version), default is long version

Examples:
Loading two files locally and outputting results to console:
java -jar bubastis.jar -1 "file:H://obi_nov_08.owl" -2 "file:H://obi_jan_09.owl"

Loading two files locally and outputting results to text file in summary format:
java -jar bubastis.jar -1 "file:H://obi_nov_08.owl" -2 "file:H://obi_jan_09.owl" -t "H://OBIdiff.txt" -s

Loading one file locally and one from the web and outputting results to console:
java -jar bubastis.jar -1 "file:H://efo_1_3.owl" -2 www.ebi.ac.uk/efo/efo.owl 