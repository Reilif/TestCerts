# TestCerts
Im Folgenden findet der geneigte Leser eine kleine Einführung in die Zertifikatserzeugung mit OpenSSL für das PKI42 Projekt.

## Wichtiger Hinweis
In den Configurations-Dateien findet sich als erster gesetzter Parameter (**dir**) das Stammverzeichnis. Dieser Pfad muss absolut sein. Auf Linuxsystemen empfiehlt es sich das ganz auf oberster ebene abzulegen "/root/ca" oder ähnliches. Immer wenn ein PW benötigt wird ist das im Folgenden: asdfg

## CA-Root
Alle Dateien die zur Erstellung des Root-Certifikates benötigt werden liegen im Verzeichnis root/ca. Das Verzeichnis cert enthält das Root-CA-Cert, in private liegt der Key. Mit dem Root Certificate dürfen für Intermediate-Certs ausgestellt werden! Alles andere muss über das Intermediate-Cert signiert werden.

Im Folgenden wird die Erzeugung des CA-Root-Zerts beschrieben. Inkl. aller notwendigen Schritte. Befehle werden für Linux notiert, lassen sich aber auch meist unter Windoof nutzen.

### Vorbereitung

#### Anlegen aller benötigten Ordner und Dateien
```bash
mkdir /root/ca
cd /root/ca
mkdir certs crl newcerts private
chmod 700 private
touch index.txt
echo 1000 > serial
```
#### Konfigurationsfile
Das fertige .cnf-File findet sich im Verzeichnis root/ca/openssl.cnf. Diese sollte einfach kopiert werden und die dir-Variable angepasst werden. Auch die Standardwerte können in der Section _default angepasst werden. Für das Root Certificate ist die extension v3_ca wichtig (mit **[v3_ca]**) gekennzeichnet. Für der Intermediate Certificate ist der Absatz **[v3_intermediate_ca]** entscheident. Dabei ist die gesetzte Variable `pathlen:0` entscheidend. Dies beschärnkt die IC als letzte signing CA.

### Root-Key erzeugen

```bash
# cd /root/ca
# openssl genrsa -aes256 -out private/ca.key.pem 4096

Enter pass phrase for ca.key.pem: secretpassword
Verifying - Enter pass phrase for ca.key.pem: secretpassword

# chmod 400 private/ca.key.pem
```
### Root-Cert erzeugen

```bash
# cd /root/ca
# openssl req -config openssl.cnf \
      -key private/ca.key.pem \
      -new -x509 -days 7300 -sha256 -extensions v3_ca \
      -out certs/ca.cert.pem

Enter pass phrase for ca.key.pem: secretpassword
You are about to be asked to enter information that will be incorporated
into your certificate request.
-----
Country Name (2 letter code) [XX]:DE
State or Province Name []:NRW
Locality Name []:Minden
Organization Name []:FH Bielefeld
Organizational Unit Name []:PKI42
Common Name []:PKI42 Root CA
Email Address []:

# chmod 444 certs/ca.cert.pem
```

Die eingegebenen Informationen sollten sich gemerkt werden. Intermediate-Certs müssen die gleichen Daten haben abgesehen vom CN.

### Root Zertifikat verifizieren`
```bash
# openssl x509 -noout -text -in certs/ca.cert.pem
```

Issuer und Subject sollten identisch sein, typisches anzeichen für self-signed. Wichtig ist die Extension diese sollte **v3_ca** anzeigen

## Intermediate Zertifikat
Das Intermediate Zertifikat ist die Nutz-CA. Das Root-CA bleibt unter Verschluss und wird nicht angefasst. Das Intermediate Zertifikat bekommt eine ähnliche Struktur wie die Root-CA. Mit einer leicht veränderten .cnf-File.

### Vorbereitung

```bash
# mkdir /root/ca/intermediate
# cd /root/ca/intermediate
# mkdir certs crl csr newcerts private
# chmod 700 private
# touch index.txt
# echo 1000 > serial
# echo 1000 > /root/ca/intermediate/crlnumber
```

