#!/bin/sh

cat >&2

cat <<END
200 OK

<html>
<head>
<title>WLAN Konfiguration</title>
</head>
<body>
<form method="post" action="#">
<label>Netzwerk:
<select name="network">
$(iwlist wlan0 scan | sed -n 's|^.*ESSID:"\([^"]*\)"$|<option>\1</option>|p' | sort -u)
</select>
</label>
<label>Passwort:
<input type="text" name="password" />
</label>
<input type="submit" name="Absenden" />
</form>
</body>
</html>
END