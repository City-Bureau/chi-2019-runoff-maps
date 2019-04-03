.PRECIOUS: aggspread data/parcels.geojson input/cook-parcels.geojson

CANDIDATES = lightfoot preckwinkle
CANDIDATE_FIELDS = lightfoot,preckwinkle
RENAME_FIELDS = lightfoot="LORI LIGHTFOOT",preckwinkle="TONI PRECKWINKLE"
DENSITY_DIVIDE = 5
mapshaper_cmd = node --max_old_space_size=4096 $$(which mapshaper)

data/dots.mbtiles: data/dots.geojson
	tippecanoe -L results:$< --drop-densest-as-needed --maximum-zoom=12 --no-tile-stats --force -B10 --maximum-tile-bytes=1000000 -o $@

data/dots.geojson: $(patsubst %, data/candidates/%.geojson, $(CANDIDATES))
	mapshaper -i $^ combine-files -merge-layers -o $@

data/candidates/%.geojson: data/candidates/%.csv
	mapshaper $< -points x=lon y=lat -each 'candidate = "$*"' -filter-fields candidate -o $@

data/candidates/%.csv: data/election.geojson data/parcels.geojson aggspread
	./aggspread -agg $< -prop $* -spread data/parcels.geojson -output $@

data/parcels.geojson: input/cook-parcels.geojson data/clip.geojson
	$(mapshaper_cmd) -i $< \
	-erase $(filter-out $<,$^) remove-slivers \
	-clip bbox=-87.872877,41.644796,-87.502688,42.025769 remove-slivers \
	-filter '!!BLDGClass && BLDGClass.startsWith("2")' \
	-filter-fields PIN14 \
	-o $@ format=geojson

# Create a file with all of Cook County excluding Chicago for erasing from the parcel layer
data/clip.geojson: input/cook.geojson input/chicago.geojson
	$(mapshaper_cmd) -i $< -erase $(filter-out $<,$^) remove-slivers -o $@

data/election.geojson: input/results.geojson
	mapshaper -i $< \
	-rename-fields $(RENAME_FIELDS) \
	-filter-fields $(CANDIDATE_FIELDS) \
	$(foreach c, $(CANDIDATES), -each "$(c) = Math.floor($(c)) / $(DENSITY_DIVIDE) || 0") \
	-o $@ format=geojson

input/cook.geojson:
	wget -O $@ 'https://datacatalog.cookcountyil.gov/api/geospatial/ihae-id2m?method=export&format=GeoJSON'

input/chicago.geojson:
	wget -O $@ 'https://data.cityofchicago.org/api/geospatial/sp34-6z76?method=export&format=GeoJSON'

input/cook-parcels.geojson:
	esri2geojson -f PIN14,BLDGClass --proxy "https://maps.cookcountyil.gov/cookviewer/proxy/tempProxy.ashx?" "https://gis1.cookcountyil.gov/arcgis/rest/services/cookVwrDynmc/MapServer/44" -v $@

aggspread: aggspread-darwin-amd64.tar.gz
	tar -xzvf $<
	mv release/aggspread-darwin-amd64/$@ $@
	rm -r release

aggspread-darwin-amd64.tar.gz:
	wget -O $@ https://github.com/pjsier/aggspread/releases/download/v0.0.1/aggspread-darwin-amd64.tar.gz
