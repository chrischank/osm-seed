#!/usr/bin/env bash

WORKDIR=/apps
DATA_DIR=$WORKDIR/data
UPDATE_DIR=$DATA_DIR/update
DOWNLOAD_DIR=$DATA_DIR/download

mkdir -p $DATA_DIR
# Update dir values in taginfo-config.json
grep -v '^ *//' $WORKDIR/taginfo/taginfo-config-example.json |
    jq '.logging.directory                   = "'$UPDATE_DIR'/log"' |
    jq '.paths.download_dir                  = "'$UPDATE_DIR'/download"' |
    jq '.paths.bin_dir                       = "'$WORKDIR'/taginfo-tools/build/src"' |
    jq '.sources.db.planetfile               = "'$UPDATE_DIR'/planet/planet.osm.pbf"' |
    jq '.sources.chronology.osm_history_file = "'$UPDATE_DIR'/planet/history-planet.osh.pbf"' |
    jq '.sources.db.bindir                   = "'$UPDATE_DIR'/build/src"' |
    jq '.paths.data_dir                      = "'$DATA_DIR'"' \
        >$WORKDIR/taginfo-config.json

# Update instance values in taginfo-config.json
[[ ! -z ${INSTANCE_URL+z} ]] && jq --arg a "${INSTANCE_URL}" '.instance.url = $a' $WORKDIR/taginfo-config.json >tmp.json && mv tmp.json $WORKDIR/taginfo-config.json
[[ ! -z $INSTANCE_NAME+z} ]] && jq --arg a "${INSTANCE_NAME}" '.instance.name = $a' $WORKDIR/taginfo-config.json >tmp.json && mv tmp.json $WORKDIR/taginfo-config.json
[[ ! -z $INSTANCE_DESCRIPTION+z} ]] && jq --arg a "${INSTANCE_DESCRIPTION}" '.instance.description = $a' $WORKDIR/taginfo-config.json >tmp.json && mv tmp.json $WORKDIR/taginfo-config.json
[[ ! -z $INSTANCE_ICON+z} ]] && jq --arg a "${INSTANCE_ICON}" '.instance.icon = $a' $WORKDIR/taginfo-config.json >tmp.json && mv tmp.json $WORKDIR/taginfo-config.json
[[ ! -z $INSTANCE_CONTACT+z} ]] && jq --arg a "${INSTANCE_CONTACT}" '.instance.contact = $a' $WORKDIR/taginfo-config.json >tmp.json && mv tmp.json $WORKDIR/taginfo-config.json


# Update DBs to create
[[ ! -z $DOWNLOAD_DB+z} ]] && jq --arg a "${DOWNLOAD_DB}" '.sources.download = $a' $WORKDIR/taginfo-config.json >tmp.json && mv tmp.json $WORKDIR/taginfo-config.json
[[ ! -z $CREATE_DB+z} ]] && jq --arg a "${CREATE_DB}" '.sources.create = $a' $WORKDIR/taginfo-config.json >tmp.json && mv tmp.json $WORKDIR/taginfo-config.json

# Function to replace the repo to get the projects information
TAGINFO_PROJECT_REPO=${TAGINFO_PROJECT_REPO//\//\\/}
sed -i -e 's/https:\/\/github.com\/taginfo\/taginfo-projects.git/'$TAGINFO_PROJECT_REPO'/g' $WORKDIR/taginfo/sources/projects/update.sh

# The follow line is requiered to avoid an issue -> require cannot load such file -- sqlite3
# sed -i -e 's/run_ruby "$SRCDIR\/update_characters.rb"/ruby "$SRCDIR\/update_characters.rb"/g' $WORKDIR/taginfo/sources/db/update.sh
# sed -i -e 's/run_ruby "$SRCDIR\/import.rb"/ruby "$SRCDIR\/import.rb"/g' $WORKDIR/taginfo/sources/projects/update.sh
# sed -i -e 's/run_ruby "$SRCDIR\/parse.rb"/ruby "$SRCDIR\/parse.rb"/g' $WORKDIR/taginfo/sources/projects/update.sh
# sed -i -e 's/run_ruby "$SRCDIR\/get_icons.rb"/ruby "$SRCDIR\/get_icons.rb"/g' $WORKDIR/taginfo/sources/projects/update.sh

update() {
    echo "Download and update pbf files at $(date +%Y-%m-%d:%H-%M)"

    # Download OSM planet replication and full-history files
    mkdir -p $UPDATE_DIR/planet/
    [ ! -f $UPDATE_DIR/planet/planet.osm.pbf ] && wget --no-check-certificate -O $UPDATE_DIR/planet/planet.osm.pbf $URL_PLANET_FILE
    [ ! -f $UPDATE_DIR/planet/history-planet.osh.pbf ] && wget --no-check-certificate -O $UPDATE_DIR/planet/history-planet.osh.pbf $URL_HISTORY_PLANET_FILE

    # Update pbf files ussing replication files, TODO, fix the certification issue
    # pyosmium-up-to-date \
    #     -v \
    #     --size 5000 \
    #     --server $REPLICATION_SERVER \
    #     $UPDATE_DIR/planet/history-planet.osh.pbf

    # pyosmium-up-to-date \
    #     -v \
    #     --size 5000 \
    #     --server $REPLICATION_SERVER \
    #     $UPDATE_DIR/planet/planet.osm.pbf

    # Update local DB
    sed -i -e 's/set -euo pipefail/set -x/g' $WORKDIR/taginfo/sources/update_all.sh

    $WORKDIR/taginfo/sources/update_all.sh $UPDATE_DIR

    mv $UPDATE_DIR/*/taginfo-*.db $DATA_DIR/
    mv $UPDATE_DIR/taginfo-*.db $DATA_DIR/

    # Link to download db zip files
    chmod a=r $UPDATE_DIR/download
    ln -sf $UPDATE_DIR/download $WORKDIR/taginfo/web/public/download
}

start_web() {
    echo "Start taginfo..."
    cd $WORKDIR/taginfo/web && bundle exec rackup --host 0.0.0.0 -p 4567
}

continuous_update() {
    while true; do
        update
        sleep $TIME_UPDATE_INTERVAL
    done
}

main() {
    # Check if db files are store in the $DATA_DIR
    NUM_DB_FILES=$(ls $DATA_DIR/*.db | wc -l)
    if [ $NUM_DB_FILES -lt 7 ]; then
        # We are changing the default values, we need to run update twice at the beginning
        update
        update
    fi
    start_web &
    continuous_update
}

update
