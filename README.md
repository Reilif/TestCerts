# TestCerts
Im Folgenden findet der geneigte Leser eine kleine Einführung in die Zertifikatserzeugung mit OpenSSL für das PKI42 Projekt.

## Wichtiger Hinweis
In den Configurations-Dateien findet sich als erster gesetzter Parameter (dir) das Stammverzeichnis. Dieser Pfad muss absolut sein. Auf Linuxsystemen empfiehlt es sich das ganz auf oberster ebene abzulegen "/root/ca" oder ähnliches. Immer wenn ein PW benötigt wird ist das im Folgenden: asdfg

## CA-Root
Alle Dateien die zur Erstellung des Root-Certifikates benötigt werden liegen im Verzeichnis root/ca. Das Verzeichnis cert enthält das Root-CA-Cert, in private liegt der Key. Mit dem Root Certificate dürfen für Intermediate-Certs ausgestellt werden! Alles andere muss über das Intermediate-Cert signiert werden.

Im Folgenden wird die Erzeugung des CA-Root-Zerts beschrieben. Inkl. aller notwendigen Schritte. Befehle werden für Linux notiert, lassen sich aber auch meist unter Windoof nutzen.

### Vorbereitung

#### Anlegen aller benötigten Ordner und Dateien
mkdir /root/ca
cd /root/ca
mkdir certs crl newcerts private
chmod 700 private
touch index.txt
echo 1000 > serial

#### Konfigurationsfile
Das fertige .cnf-File findet sich im Verzeichnis root/ca/openssl.cnf. Diese sollte einfach kopiert werden und die dir-Variable angepasst werden
