include dots.mk runoff.mk

S3_BUCKET = chicago-election-2019

.PHONY: all deploy tiles

all: data/wards.mbtiles data/precincts.mbtiles

deploy:
	aws s3 cp ./tiles s3://$(S3_BUCKET)/runoff/tiles/ --recursive --acl=public-read --content-encoding=gzip --region=us-east-1
	aws s3 cp ./maps s3://$(S3_BUCKET)/runoff/ --recursive --acl=public-read --region=us-east-1

tiles:
	for f in ./data/*.mbtiles; do tile-join --no-tile-size-limit --force -e ./tiles/$$(basename $$f .mbtiles) $$f; done

input/results.geojson:
	wget -O $@ https://raw.githubusercontent.com/datamade/chicago-municipal-elections/master/data/municipal_general_2019.geojson
