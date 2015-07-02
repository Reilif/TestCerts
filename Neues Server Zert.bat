cd "C:\OpenSSL-Win32\bin\Test\TestCerts\root\ca"
set /p certname=Name für das Zertifikat:

openssl genrsa -out intermediate/private/%certname%.key.pem

openssl req -config intermediate/openssl.cnf -key intermediate/private/%certname%.key.pem -new -sha256 -out intermediate/csr/%certname%.csr.pem

openssl ca -config intermediate/openssl.cnf -extensions server_cert -days 375 -notext -md sha256 -in intermediate/csr/%certname%.csr.pem -out intermediate/certs/%certname%.cert.pem

pause