#!/bin/bash

MODULE_NAME=Ably
UMBRELA_HEADER=Ably.h
SOURCE_DIRECTORY=../Source
FILE_NAME="${MODULE_NAME}.modulemap"
DESTINATION_DIRECTORY=../include/
PRIVATE_SUFFIX=*Private.h
COPY_HEADERS_SOURCES=("../Source" "../SocketRocket/SocketRocket")
HEADERS=(ARTConstants.h ARTReachability.h ARTURLSession.h ARTURLSessionServerTrust.h ARTRealtimeTransport.h ARTWebSocketTransport.h ARTWebSocket.h ARTNSMutableRequest+ARTPush.h ARTNSMutableRequest+ARTRest.h ARTNSHTTPURLResponse+ARTPaginated.h ARTNSMutableURLRequest+ARTPaginated.h ARTNSDate+ARTUtil.h ARTQueuedDealloc.h ARTJsonLikeEncoder.h ARTJsonEncoder.h ARTMsgPackEncoder.h ARTFormEncode.h ARTSRWebSocket.h)

FULLPATH=$DESTINATION_DIRECTORY$FILE_NAME

# clear directory
rm -rf $DESTINATION_DIRECTORY$MODULE_NAME
mkdir $DESTINATION_DIRECTORY$MODULE_NAME


for source in ${COPY_HEADERS_SOURCES[*]}
do
    find $source -type f -and -name "*.h" -exec ln -s "../{}" $DESTINATION_DIRECTORY$MODULE_NAME \;
done

# #symlink Source directory
# find $SOURCE_DIRECTORY -type f -and -name "*.h" -exec ln -s "../../{}" $DESTINATION_DIRECTORY$MODULE_NAME \;

# #symlink SocketRocket directory
# find ../SocketRocket/SocketRocket -type f -and -name "*.h" -exec ln -s "../../{}" $DESTINATION_DIRECTORY$MODULE_NAME \;

if [ -f "$FULLPATH" ]; then
    rm $FULLPATH
fi

touch $FULLPATH

while IFS=  read -r -d $'\0'; do
    HEADERS+=("$REPLY")
done < <(find $SOURCE_DIRECTORY -type f -and -name $PRIVATE_SUFFIX -print0)

echo "framework module $MODULE_NAME {" >> $FULLPATH
echo -e "\tumbrella header \"$MODULE_NAME/$UMBRELA_HEADER\"" >> $FULLPATH
echo "" >> $FULLPATH
echo -e "\texport *" >> $FULLPATH
echo -e "\tmodule * { export * }" >> $FULLPATH
echo "" >> $FULLPATH
echo -e "\texplicit module Private {" >> $FULLPATH

for item in ${HEADERS[*]}
do
    BASENAME=$(echo "$item" | xargs -0 -n1 basename)
    echo -e "\t\theader \"${MODULE_NAME}/$BASENAME\"" >> $FULLPATH
done

echo -e "\t}" >> $FULLPATH
echo "}" >> $FULLPATH