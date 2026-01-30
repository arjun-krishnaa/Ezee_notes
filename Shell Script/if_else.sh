#!/bin/bash

DEST="/home"
LOGFILE="/home/logfile.txt"

# Clear logfile
: > "$LOGFILE"

echo "Searching start" >> "$LOGFILE"

# Check if any file larger than 4KB exists in /home
if find "$DEST" -type f -size +4k | grep -q .; then
    echo "Yes. I found" >> "$LOGFILE"
else
    echo "Not Found" >> "$LOGFILE"
fi

------------------------------------------------------------------------

#!/bin/bash

DEST="/home/*"
LOGFILE="/home/logfile.txt"

true > $LOGFILE

echo "searching start" > $LOGFILE

if [-f -size +4kb $DEST]

echo "Yes. I found"

else 

echo "Not Found"

fi

----------------------------------------------------------------------------

#!/bin/bash

DEST="/home/*"
LOGFILE="/home/logfile.txt"

true > $LOGFILE

if find "$DEST" -type f -size +60k | grep -q ; then  
    echo "Yes I found 60k file"

elif find "$DEST" -type f -size +55k | grep -q ; then 
    echo "Yes I found 55k file"

elif find "$DEST" -type f -size +50k | grep -q ; then 
    echo "Yes I found 50k file"

else   
    echo "Not Found"

fi


