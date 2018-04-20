# ___________________________________________________________________________________
# This script is licensed under the MIT license. (http://opensource.org/licenses/MIT)
# Credits: Pierre-Edouard Barrault
# http://pierrz.com 

# Script designed in order to pull statistics from the Europeana Search API and feed into shared Google Spreadsheets.
# Mainly bypass the limitations of ImportJSON.gs script regarding the max URL lenght it can fetch 
# (Extra long URLs tend to be an outcome of using extensive Thematic collections queries).

# !/bin/bash

echo "__________________________________"
echo "__________________________________"
echo "###        STATS SCRIPT        ###"
echo "__________________________________"
echo "__________________________________"

#___________________
# TIMESTAMP FUNCTION
timestamp() {
  date +"_%Y-%m-%dT%H:%M:%S"
}
DATE=$(timestamp)



#___________________
# QUERY PARAMETERS

# Output directory
dirOutput="output/"
separator="___"

# API key
apiKey=$(cat API_key.txt)
query_apikey_param="&wskey="
query_apikey="$query_apikey_param$apiKey"

# MAIN GEARS

# Whole Europeana DB
query_baseUrl="https://www.europeana.eu/api/v2/search.json?start=1&rows=0"

# With Thematic Collection query fetched from separate txt file
  # query_theme=$(cat themes/query_migration.txt)
  # query_baseUrl_qf="https://www.europeana.eu/api/v2/search.json?start=1&rows=0&qf="

# FIELDS
label_edmDatasetName="edm_datasetName"
label_dcCreator="proxy_dc_creator"
label_dcContributor="proxy_dc_contributor"
label_dcPublisher="proxy_dc_publisher"
label_dcType="proxy_dc_type"
label_dcFormat="proxy_dc_format"
label_dctExtent="proxy_dcterms_extent"
label_dctExtent="proxy_dcterms_medium"

# @lang ISO codes
facet_intro="&facet="
facet_trail="&f."

# FACET LIMIT
query_facetOn="&profile=facets"
facet_limit_nb=10000
facet_limit=".limit=$facet_limit_nb"

# VARIOUS
json_ext="json"
separator="__"


# CURRENT QUERY
query_input="&query=$label_edmDatasetName:"
# query_dataProv="&query=DATA_PROVIDER:%22"
# query_type="%22%20AND%20TYPE:"
# facet_rights="%22&reusability=
query_this_intro="$query_baseUrl$query_apikey$query_facetOn$query_input"

# INPUT FILE
input_file="input/list_languages.csv"



#____________________________________________
# SCRIPT

# Start dataset increment on 2nd line
i=2
# Max amount of datasets
max=$( csvtool height "$input_file")
# Max amount of facets
width=$( csvtool -t ";" width "$input_file")

# LOOP for each line/dataset
while [ "$i" -le "$max" ]; do
    
    # Setting dataset id separately
    csvtool -t ";" col 1 -o "tmp/col_1.txt" "$input_file"    # Pulling related column file
    col_file_dataset="tmp/col_1.txt"                          # Setting datasets file
    datasetIddi=$( sed "${i}q;d" "$col_file_dataset" )        # Current dataset value picked from nth line of datasets file
    datasetId="$datasetIddi*"                                 # Final tuning with wildcard '*'

    # Setting the related facets/columns, starting on 2nd col.
    # And Pulling the related queries
    colPos=2
    while [ "$colPos" -le "$width" ]; do
        
        # Pulling the rest of the columns files only once
        if [ "$i" -eq 2 ]; then
            csvtool -t ";" col "$colPos" -o "tmp/col_$colPos.txt" "$input_file"    
        fi
            
        # Current main parameters
        col_file="tmp/col_$colPos.txt"
        current_facet=$(cat "$col_file" | sed "1q;d" )    # Current facet label picked from 1st line of current column/facet file
        val=$( sed "${i}q;d" "$col_file" )                 # Current facet value picked from nth line of current column/facet file
        echo "--------> DATASET $datasetIddi"
        echo "--------------> FACET $current_facet"
        current_file="$dirOutput$datasetIddi$separator$current_facet"

        # .def lang parameters
        def="def"
        facet_full_def="$facet_intro$current_facet.$def$facet_trail$current_facet.$def$facet_limit"
        query_full_def="$query_this_intro$datasetId$facet_full_def"
        current_file_final_def="$current_file.$def.$json_ext"

        # IF facet value different from 'X'
        if [ "$val" != "X" ]; then

            # Checking lenght of string value
            len=${#val}
            maxLen=3    # Max lenght set to 3 (en;fr;pol;en.fr)

            # IF facet string value longer than 3, tokenized values on '.' + def attribute
            if [ "$len" -gt "$maxLen" ]; then
            # if [ "$val" == *","* ]; then
        	echo "-----------------------> LANGUAGE(S) = MULTIPLE + DEF "

                # Workarounf for 2 values scenario
                iso1=${val%.*}
                iso2=${val#*.}

                facet_full_iso1="$facet_intro$current_facet.$iso1$facet_trail$current_facet.$iso1$facet_limit"
                facet_full_iso2="$facet_intro$current_facet.$iso2$facet_trail$current_facet.$iso2$facet_limit"
                query_full_iso1="$query_this_intro$datasetId$facet_full_iso1"
                query_full_iso2="$query_this_intro$datasetId$facet_full_iso2"

                current_file_final_iso1="$current_file.$iso1.$json_ext"
                current_file_final_iso2="$current_file.$iso2.$json_ext"

                echo "-----------------------------> @xml:lang = '$iso1' "
                wget -O "$current_file_final_iso1" "$query_full_iso1"
                echo "-----------------------------> @xml:lang = '$iso2' "
                wget -O "$current_file_final_iso2" "$query_full_iso2"
                echo "-----------------------------> @xml:lang = 'def' "
                wget -O "$current_file_final_def" "$query_full_def"

            # IF facet string value shorter than 3, unique value/attribute + def
            elif [ "$len" -le "$maxLen" ]; then
            echo "-----------------------> LANGUAGE(S) = UNIQUE + DEF "
                facet_full_uni="$facet_intro$current_facet.$val$facet_trail$current_facet.$val$facet_limit"
                query_full_uni="$query_this_intro$datasetId$facet_full_uni"
                current_file_final_uni="$current_file.$val.$json_ext"

                echo "-----------------------------> @xml:lang = '$val' "
                wget -O "$current_file_final_uni" "$query_full_uni"
                echo "-----------------------------> @xml:lang = 'def' "
                wget -O "$current_file_final_def" "$query_full_def"

            fi

            # IF facet value equals to 'X', '.def' attribute only
            else
            echo "-----------------------> LANGUAGE(S) = DEF only "

            	echo "-----------------------------> @xml:lang = 'def' "
                wget -O "$current_file_final_def" "$query_full_def"
        fi

        #Increment for facets/columns
        colPos=$(( colPos + 1 ))
    done
    
    #Increment for datasets/lines
    i=$(( i + 1 ))

done

# _________________________
# ZIPPING full output
echo ""
echo "+++++++++++++++++++++++"
echo "Zipping JSON results"
echo ""
cd output
zip "../zips/stats_photoconsortium_$DATE.zip" *.json
cd ..

# echo "DONE"

exit 0;