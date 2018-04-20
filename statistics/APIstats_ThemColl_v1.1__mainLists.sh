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
echo "###      MAIN LISTS SCRIPT     ###"
echo "__________________________________"
echo "__________________________________"



# TIMESTAMP FUNCTIONS
timestamp() {
  date +"_%Y-%m-%dT%H:%M:%S"
}
DATE=$(timestamp)



# QUERY PARAMETERS

# Output directory
dirOutput="output/migration/mainLists/"

# Thematic Collection query fetched from separate txt file
query_main=$(cat themes/query_migration.txt)

# API key
apiKey=$(cat API_key.txt)
query_apikey_param="&wskey="
query_apikey="$query_apikey_param$apiKey"

# Search API main gears
query_baseUrl="https://www.europeana.eu/api/v2/search.json?start=1&rows=0&qf="
json_ext="json"

# Query parameter
query_all="&query=*"

# Facets
facet_dataProvider="&profile=facets&facet=DATA_PROVIDER&f.DATA_PROVIDER.facet.limit=2000"
facet_provider="&profile=facets&facet=PROVIDER&f.PROVIDER.facet.limit=2000"



query_facet_dataProvider="$query_baseUrl$query_main$query_all$facet_dataProvider$query_apikey"
query_facet_provider="$query_baseUrl$query_main$query_all$facet_provider$query_apikey"

dataProvider_labelFile="migration_dataProviders"
provider_labelFile="migration_providers"

file_dataProvider="$dirOutput$dataProvider_labelFile.$json_ext"
file_provider="$dirOutput$provider_labelFile.$json_ext"



# LISTS
  echo "______"
  echo "   |---> DATA PROVIDERS LIST"
  wget -O "$file_dataProvider" "$query_facet_dataProvider"
  echo ""
  echo "   |---> PROVIDERS LIST"
  wget -O "$file_provider" "$query_facet_provider"
  echo ""



# ZIPPING full output
echo "+++++++++++++++++"
echo "Zipping JSON results"
echo ""
cd output/migration/mainLists
zip "../../../zips/stats_migration_mainLists_$DATE.zip" *.json
cd ../../..

exit 0;