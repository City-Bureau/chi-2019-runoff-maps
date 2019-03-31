WARDS = 5 6 15 16 20 21 25 30 31 33 39 40 43 46 47
wards-zoom = 9
precincts-zoom = 11

data/%.mbtiles: data/%.geojson
	$(eval geo=$(word 1, $(subst -, ,$*)))
	tippecanoe --simplification=10 --simplify-only-low-zooms --maximum-zoom=$($(geo)-zoom) --no-tile-stats \
	--force --detect-shared-borders --coalesce-smallest-as-needed -L $*:$< -o $@

data/wards.geojson: data/wards.csv input/wards.geojson
	mapshaper -i $(filter-out $<,$^) -filter-fields ward \
	-join $< field-types=ward:str keys=ward,ward -o $@

data/wards.csv: data/precincts.geojson
	cat $< | python scripts/combine_precincts_wards.py > $@

data/precincts.geojson: input/results.geojson input/wards.geojson
	mapshaper -i $< -clip $(filter-out $<,$^) -o - | \
	python scripts/process_results.py --$* > $@

input/wards.geojson:
	wget -O $@ 'https://data.cityofchicago.org/api/geospatial/sp34-6z76?method=export&format=GeoJSON'

