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


# TIMESTAMP FUNCTIONS
timestamp() {
  date +"_%Y-%m-%dT%H:%M:%S"
}
DATE=$(timestamp)


# QUERY PARAMETERS

# Output directory
dirOutput="output/migration/providers/"

# Thematic Collection query fetched from separate txt file
queryTC_value=$(cat themes/query_migration.txt)
queryTC_param="&qf="
queryTC_main="$queryTC_param$queryTC_value"

# API key
apiKey=$(cat API_key.txt)
query_apikey_param="&wskey="
query_apikey="$query_apikey_param$apiKey"

# Search API main gears
query_baseUrl="https://www.europeana.eu/api/v2/search.json?start=1&rows=0"
json_ext="json"

# Query parameter
query_prov="&query=PROVIDER:%22"
query_type="%22%20AND%20TYPE:"

# Aggregated facets
facet_rights="%22&reusability="
facet_dataProvider="%22&profile=facets&facet=DATA_PROVIDER&f.DATA_PROVIDER.facet.limit=300"

# Fixed values
# Providers
dataProviders_pattern="_dataProviders"
dataProviders_pattern_all="_dataProviders_all"
# Licences
rights_pattern="_rights_"
rights_open="open"
rights_restricted="restricted"
rights_permission="permission"

# Types
type_pattern="_types_"
type_TEXT="TEXT"
type_IMAGE="IMAGE"
type_VIDEO="VIDEO"
type_SOUND="SOUND"
type_3D="3D"


# Initialisation 
# [meant to avoid any problematic filenames while staying synced with the input values]  
i=1

# echo "$queryTC_main"
# Loop on line
while IFS= read -r line
do

  # Current provider
  providerLabel=$line

  # DATA PROVIDER ALL queries
  query_facet_dataProvider_all="$query_baseUrl$query_prov$providerLabel$facet_dataProvider$query_apikey"
  # DATA PROVIDER ALL files
  file_facet_dataProvider_all="$dirOutput$i$dataProviders_pattern_all.$json_ext"

  # DATA PROVIDER queries
  query_facet_dataProvider="$query_baseUrl$queryTC_main$query_prov$providerLabel$facet_dataProvider$query_apikey"
  # DATA PROVIDER files
  file_facet_dataProvider="$dirOutput$i$dataProviders_pattern.$json_ext"
  
  # RIGHTS queries
  facet_rights_open="$query_baseUrl$queryTC_main$query_prov$providerLabel$facet_rights$rights_open$query_apikey"
  facet_rights_restricted="$query_baseUrl$queryTC_main$query_prov$providerLabel$facet_rights$rights_restricted$query_apikey"
  facet_rights_permission="$query_baseUrl$queryTC_main$query_prov$providerLabel$facet_rights$rights_permission$query_apikey"
  # RIGHTS files
  file_rights_open="$dirOutput$i$rights_pattern$rights_open.$json_ext"
  file_rights_restricted="$dirOutput$i$rights_pattern$rights_restricted.$json_ext"
  file_rights_permission="$dirOutput$i$rights_pattern$rights_permission.$json_ext"
  
  # TYPES queries
  query_type_text="$query_baseUrl$queryTC_main$query_prov$providerLabel$query_type$type_TEXT$query_apikey"
  query_type_image="$query_baseUrl$queryTC_main$query_prov$providerLabel$query_type$type_IMAGE$query_apikey"
  query_type_video="$query_baseUrl$queryTC_main$query_prov$providerLabel$query_type$type_VIDEO$query_apikey"
  query_type_sound="$query_baseUrl$queryTC_main$query_prov$providerLabel$query_type$type_SOUND$query_apikey"
  query_type_3D="$query_baseUrl$queryTC_main$query_prov$providerLabel$query_type$type_3D$query_apikey"
  # TYPES files
  file_type_text="$dirOutput$i$type_pattern$type_TEXT.$json_ext"
  file_type_image="$dirOutput$i$type_pattern$type_IMAGE.$json_ext"
  file_type_video="$dirOutput$i$type_pattern$type_VIDEO.$json_ext"
  file_type_sound="$dirOutput$i$type_pattern$type_SOUND.$json_ext"
  file_type_3D="$dirOutput$i$type_pattern$type_3D.$json_ext"
  

  # SCRIPT
  echo "++++++++++++++++++++++++++++++++++++++++++"
  echo "$providerLabel"
  echo ""

    # Data Providers
  echo "______"
  echo "Data Providers"
  echo "   |--------> ALL"
  wget -O "$file_facet_dataProvider_all" "$query_facet_dataProvider_all"
  echo "   |--------> INSIDE THEMATIC COLLECTION"
  wget -O "$file_facet_dataProvider" "$query_facet_dataProvider"
  echo ""

  # Rights
  echo "______"
  echo "RIGHTS"
  echo "reusability = open"
  wget -O "$file_rights_open" "$facet_rights_open"
  echo "reusability = restricted"
  wget -O "$file_rights_restricted" "$facet_rights_restricted"
  echo "reusability = permission"
  wget -O "$file_rights_permission" "$facet_rights_permission"
  echo ""

  # Types
  echo "_____"
  echo "TYPES"
  echo "TEXT"
  wget -O "$file_type_text" "$query_type_text"
  echo "IMAGE"
  wget -O "$file_type_image" "$query_type_image"
  echo "VIDEO"
  wget -O "$file_type_video" "$query_type_video"
  echo "SOUND"
  wget -O "$file_type_sound" "$query_type_sound"
  echo "3D"
  wget -O "$file_type_3D" "$query_type_3D"

  #Increment
  i=$(( i + 1 ))

# INPUT .txt file (list of data providers, with /!\ last line being empty /!\ )
done < "input/migration_providers.txt"

# ZIPPING full output
echo "+++++++++++++++++"
echo "Zipping JSON results"
echo ""
cd output/migration/providers
zip "../../../zips/stats_migration_providers_$DATE.zip" *.json
cd ../../..

exit 0;