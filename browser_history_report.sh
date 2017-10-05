#!/bin/bash

echo "starting $(date)";
## Creating Variables

#Mail
MAIL_ADDRESS="dest_email_address_here@gmail.com";
SUBJECT="Winicios firefox history - $(date +%d-%m-%Y" "%H:%M)";

#Mozilla
PLACES_SQLITE=/home/wi/.mozilla/firefox/gtd57dtt.default/places.sqlite;

#Chrome
HISTORY_SQLITE=/home/wi/.config/google-chrome/Default/History;

#Files
CHROME_HISTORY=~/.bin/chrome_history.txt;
HISTORY=~/.bin/history.txt;
HOSTS=~/.bin/hosts.txt;
MAIL=~/.bin/mail.html;


## Collecting info
echo "collecting info from firefox";

sqlite3 $PLACES_SQLITE "select '',strftime('%d-%m-%Y %H:%M',datetime(h.visit_date/1000000,'unixepoch')), p.visit_count, p.title, p.url, p.hidden, p.typed, i.input,'' from  moz_historyvisits as h left join moz_places p on h.place_id = p.id left join moz_inputhistory as i on p.id = i.place_id order by h.visit_date desc;" > $HISTORY;

sqlite3 $PLACES_SQLITE "select '',prefix,host,'' from moz_hosts order by host;" > $HOSTS;

# Cleaning firefox history up
# Doing it here because the info is already on the files, and I dont want to lose any data if something goes wrong after this point
sqlite3 $PLACES_SQLITE "delete from moz_inputhistory;";
sqlite3 $PLACES_SQLITE "delete from moz_historyvisits;";
sqlite3 $PLACES_SQLITE "delete from moz_hosts;";
sqlite3 $PLACES_SQLITE "delete from moz_places;";


echo "Collecting info from google chrome";

sqlite3 $HISTORY_SQLITE "select '',strftime('%d-%m-%Y %H:%M',datetime(v.visit_time/1000000,'unixepoch')), u.visit_count, u.title, u.url, u.hidden, k.lower_term,'' from  visits as v left join urls u on v.url = u.id left join keyword_search_terms as k on u.id = k.url_id order by v.visit_time desc;" > $CHROME_HISTORY;

# Cleaning chrome history up
# Doing it here because the info is already on the files, and I dont want to lost any data if something goes wrong after this point
sqlite3 $HISTORY_SQLITE "delete from visits;";
sqlite3 $HISTORY_SQLITE "delete from keyword_search_terms;";
sqlite3 $HISTORY_SQLITE "delete from urls;";

# Creating mail file
echo "Creating mail file";

# Reading hosts info
sed -s 's/|//g' $HOSTS | sed 's/^/<br>/g' | sed '1s/^/<br><br><hr><h3>Hosts<\/h3><hr>/'  >  $MAIL;

# Reading firefox history info
sed 's/.$/<\/td><\/tr>/' $HISTORY | sed 's/^./<tr><td>/g' | sed -s 's/|/<\/td><td>/g' | sed '1s/^/<br><br><hr><h3>Firefox History<\/h3><hr><br><table border="1"><tr><th>Date<\/th><th>Visit Count<\/th><th>Title<\/th><th>URL<\/th><th>Hidden<\/th><th>Typed<\/th><th>Input<\/th><\/tr>/' | sed -e '$a\<\/table>' >> $MAIL;


# Reading chrome history info
sed 's/.$/<\/td><\/tr>/' $CHROME_HISTORY | sed 's/^./<tr><td>/g' | sed -s 's/|/<\/td><td>/g' | sed '1s/^/<br><br><hr><h3>Chrome History<\/h3><hr><br><table border="1"><tr><th>Date<\/th><th>Visit Count<\/th><th>Title<\/th><th>URL<\/th><th>Hidden<\/th><th>Input<\/th><\/tr>/' | sed -e '$a\<\/table>' >> $MAIL;



if [ ! -s $MAIL ]; then echo "<hr><br><h3>No History</h3><br><hr>" > $MAIL; fi;

## Sending email

# Checking connectivity before try to send mail
echo "Checking internet connectivity";

itest=$(fping google.com | grep alive);

while [ "$itest" == "" ] 
        do
	echo "Without internet connection..."
        sleep 5
        itest=$(fping google.com | grep alive)
done
echo "Successfully connected";

echo "Sending Mail";

mail -a "Content-Type:text/html;charset=UTF-8;format=flowed" -s "$SUBJECT" $MAIL_ADDRESS < $MAIL;

# Removing created files
rm -rf $HISTORY $HOSTS $MAIL $CHROME_HISTORY;

# All Done :)
echo "all done $(date)"
