#!/bin/sh

cat <<'END'
HTTP/1.0 200 OK
Connection: close

<html>
<head>
<title>WLAN Konfiguration</title>
</head>
<body>
<form method="post" action="#">
<label>Netzwerk:
<select name="network">
END
iwlist wlan0 scan | sed -n 's|^.*ESSID:"\([^"]*\)"$|<option>\1</option>|p' | sort -u
cat <<'<END'
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