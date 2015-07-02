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
 cd /root/ca
 openssl genrsa -aes256 -out private/ca.key.pem 4096

Enter pass phrase for ca.key.pem: secretpassword
Verifying - Enter pass phrase for ca.key.pem: secretpassword

 chmod 400 private/ca.key.pem
```
### Root-Cert erzeugen

```bash
 cd /root/ca
 openssl req -config openssl.cnf \
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

 chmod 444 certs/ca.cert.pem
```

Die eingegebenen Informationen sollten sich gemerkt werden. Intermediate-Certs müssen die gleichen Daten haben abgesehen vom CN.

### Root Zertifikat verifizieren`
```bash
 openssl x509 -noout -text -in certs/ca.cert.pem
```

Issuer und Subject sollten identisch sein, typisches anzeichen für self-signed. Wichtig ist die Extension diese sollte **v3_ca** anzeigen

## Intermediate Zertifikat
Das Intermediate Zertifikat ist die Nutz-CA. Das Root-CA bleibt unter Verschluss und wird nicht angefasst. Das Intermediate Zertifikat bekommt eine ähnliche Struktur wie die Root-CA. Mit einer leicht veränderten .cnf-File.

### Vorbereitung

```bash
 mkdir /root/ca/intermediate
 cd /root/ca/intermediate
 mkdir certs crl csr newcerts private
 chmod 700 private
 touch index.txt
 echo 1000 > serial
 echo 1000 > /root/ca/intermediate/crlnumber
```

Es sollte wieder die Konfigurationsdatei aus dem Verzeichnis /root/ca/intermediate genutzt werden **openssl.cnf**
**Ändert auch dort die dir-Variable**

### Intermediate-Schlüssel erzeugen

```bash
 cd /root/ca
 openssl genrsa -aes256 \
      -out intermediate/private/intermediate.key.pem 4096

Enter pass phrase for intermediate.key.pem: secretpassword
Verifying - Enter pass phrase for intermediate.key.pem: secretpassword

 chmod 400 intermediate/private/intermediate.key.pem
```

### Intermediate Zertifikat erzeugen

Hierbei auf die richtigen Daten achten. Sollten identisch mit dem Root-Ca sein, außer der CN. Achtet auch auf das richtige Config-File.

```bash
# cd /root/ca
# openssl req -config intermediate/openssl.cnf -new -sha256 \
      -key intermediate/private/intermediate.key.pem \
      -out intermediate/csr/intermediate.csr.pem

Enter pass phrase for intermediate.key.pem: secretpassword
You are about to be asked to enter information that will be incorporated
into your certificate request.
-----
Country Name (2 letter code) [XX]:DE
State or Province Name []:NRW
Locality Name []: Minden
Organization Name []:FH Bielefeld
Organizational Unit Name []:PKI42
Common Name []:PKI42 Intermediate CA
Email Address []:
```

### Inter-Zert von Root-CA signieren

Dazu wird jetzt die **v3_intermediate_ca** Extension genutzt die im Konfig-File liegt.
**Wichtig: Diesmal wird die .cnf der Root-CA genutzt**

```bash
 cd /root/ca
 openssl ca -config openssl.cnf -extensions v3_intermediate_ca \
      -days 3650 -notext -md sha256 \
      -in intermediate/csr/intermediate.csr.pem \
      -out intermediate/certs/intermediate.cert.pem

Enter pass phrase for ca.key.pem: secretpassword
Sign the certificate? [y/n]: y

 chmod 444 intermediate/certs/intermediate.cert.pem
```

Die **index.txt** im ca-Verzeichnis sollte jetzt eine neue Zeile für das Inter-Zert beinhalten.

### Inter-Zert verifizieren

Datenüberprüfen:

```bash
 openssl x509 -noout -text \
      -in intermediate/certs/intermediate.cert.pem
```

Inter-Zert gegen Root-CA verifizieren:

```bash
 openssl verify -CAfile certs/ca.cert.pem \
      intermediate/certs/intermediate.cert.pem

intermediate.cert.pem: OK
```

### Chain-Zertifikat erzeugen
Das Chain Zertifikat wird benötigt, damit das Intermediate Zertifikat die Informationen über das Root-CA beinhaltet. Damit können Clients die Verbindung herstellen. Sie wird nicht benötigt wenn das Root-Zert auf allen Client-PCs installiert wird **Empfohlen**

```bash
 cat intermediate/certs/intermediate.cert.pem \
      certs/ca.cert.pem > intermediate/certs/ca-chain.cert.pem
 chmod 444 intermediate/certs/ca-chain.cert.pem
```

## OCSP

Damit ein OCSP-Server genutzt werden kann muss allen signierten Zertifikaten die OCSP-Adresse mitgeteilt werden. Dazu muss das .cnf-File der signierenden CA angepasst werden:

```bash
[server]
#...
authorityInfoAccess = OCSP;URI:http://vm02.svrhub.de
```

###OCSP-Zertifikat erstellen

#### Schlüssel erstellen 

(damit kein PW eingegeben werden muss einfach den aes256 parameter weglassen)
```bash
 cd /root/ca
 openssl genrsa -aes256 \
      -out intermediate/private/ocsp.example.com.key.pem 4096
```

#### CSR erstellen

Alle Daten müssen der signierenden CA übereinstimmen **Nur der CN muss die fully qualified Domain des OCSP Servers besitzen**
```bash
 cd /root/ca
 openssl req -config intermediate/openssl.cnf -new -sha256 \
      -key intermediate/private/ocsp.example.com.key.pem \
      -out intermediate/csr/ocsp.example.com.csr.pem

Enter pass phrase for intermediate.key.pem: secretpassword
You are about to be asked to enter information that will be incorporated
into your certificate request.
-----
Country Name (2 letter code) [XX]:GB
State or Province Name []:England
Locality Name []:
Organization Name []:Alice Ltd
Organizational Unit Name []:Alice Ltd Certificate Authority
Common Name []:ocsp.example.com
Email Address []:
```

#### OCSP Zert signieren

Das Zert wird mit dem Inter signiert. Es wird die ocsp-Erweiterung aus der Confi genutzt

```bash
openssl ca -config intermediate/openssl.cnf \
      -extensions ocsp -days 375 -notext -md sha256 \
      -in intermediate/csr/ocsp.example.com.csr.pem \
      -out intermediate/certs/ocsp.example.com.cert.pem
```

#### OCSP Zert verifizieren

```bash
openssl x509 -noout -text \
      -in intermediate/certs/ocsp.example.com.cert.pem

    X509v3 Key Usage: critical
        Digital Signature
    X509v3 Extended Key Usage: critical
        OCSP Signing
```

## Server & Client Zertifikate erstellen

Da für Server-Zertifikate die CSR vom Kunden erzeugt werden können die Schritte **Key erzeugen & CSR erzeugen** für Serverzertifikate übersprungen werden


### Key erzeugen

```bash
 cd /root/ca
 openssl genrsa -aes256 \
      -out intermediate/private/RobinRasch.key.pem 2048
 chmod 400 intermediate/private/RobinRasch.key.pem
```

### CSR erzeugen

```bash
# cd /root/ca
# openssl req -config intermediate/openssl.cnf \
      -key intermediate/private/RobinRasch.key.pem \
      -new -sha256 -out intermediate/csr/RobinRasch.csr.pem

Enter pass phrase for www.example.com.key.pem: secretpassword
You are about to be asked to enter information that will be incorporated
into your certificate request.
-----
Country Name (2 letter code) [XX]:
State or Province Name []:
Locality Name []:
Organization Name []:
Organizational Unit Name []:
Common Name []:www.example.com
Email Address []:
```

### CSR signieren

Je nach Art des CSR (Client oder Server) muss die X509V3 extension geändert werden. Für Server: *server_cert*. Für Client: *usr_cert*.

```bash
cd /root/ca
 openssl ca -config intermediate/openssl.cnf \
      -extensions server_cert -days 375 -notext -md sha256 \
      -in intermediate/csr/RobinRasch.csr.pem \
      -out intermediate/certs/RobinRasch.cert.pem
 chmod 444 intermediate/certs/RobinRasch.cert.pem
```

Die *intermediate/index.txt* sollte jetztz einen Eintrag für dieses Zert haben

### Zert verifizieren
Hier sollte das Zert gegen das Chain-Zert verifiziert werden:

```bash
 openssl verify -CAfile intermediate/certs/ca-chain.cert.pem \
      intermediate/certs/RobinRasch.cert.pem

RobinRasch.cert.pem: OK
```

### Zert ausrollen

#### Serverzert:

Ein Webserver der die Zertifikate nutzen will benötigt folgende Dateien haben:
1. ca-chain.cert.pem
2. www.example.com.key.pem
3. www.example.com.cert.pem

Da für Server Certs aber eine CSR gestellt wurde liegt der Key schon beim Kunden.

#### Clientzert:

Da Browser nur .pfx Dateien als Client-zerts akzeptieren müssen die PEM Dateien für CC zusammen gefasst werden.

```bash
cd /root/ca
openssl pkcs12 -export -out intermediate/certs/RobinRasch.pfx -inkey intermediate/certs/RobinRasch.key.pem -in intermediate/certs/RobinRasch.cert.pem -certfile intermediate/certs/intermediate.cert.pem
```

