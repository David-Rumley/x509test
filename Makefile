# X.509 Certificate Testing driver

# Prerequisite: der2ascii and ascii2der from:
#   `go get github.com/google/der-ascii/cmd/...`

UNAME_S := $(shell uname -s)

# Use installed versions of command line tools, assumed to be in path
ifeq ($(UNAME_S),Darwin)
  PREREQS = nss gnutls openssl
  DEPS = port-install
  CERTTOOL = $(shell command -v gnutls-certtool 2> /dev/null)
else
  PREREQS = libnss3-tools gnutls-bin openssl
  DEPS = pkg-install
  CERTTOOL = $(shell command -v certtool 2> /dev/null)
endif
OPENSSL = $(shell command -v openssl 2> /dev/null)
CERTUTIL = $(shell command -v certutil 2> /dev/null)
CERTCHECK = $(shell command -v certcheck 2> /dev/null)
GOX509 = $(shell command -v ./bin/gox509 2> /dev/null)

TBS2_FILES = $(subst tbs2/,,$(wildcard tbs2/*.leaf.tbs))
TBS_FILES = $(subst tbs/,,$(wildcard tbs/*.tbs)) $(subst .leaf.tbs,.tbs,$(TBS2_FILES))

RESULTS_OPENSSL_OK = $(addprefix results/openssl/,$(subst .tbs,.out, $(TBS_FILES)))
RESULTS_GNUTLS_OK = $(addprefix results/gnutls/,$(subst .tbs,.out, $(TBS_FILES)))
RESULTS_NSS_OK = $(addprefix results/nss/,$(subst .tbs,.out, $(TBS_FILES)))
RESULTS_CERTCHECK_OK = $(addprefix results/certcheck/,$(subst .tbs,.out, $(TBS_FILES)))
RESULTS_GOX509_OK = $(addprefix results/gox509/,$(subst .tbs,.out, $(TBS_FILES)))

RESULTS_OPENSSL_XF = $(addprefix results/openssl/,$(subst .tbs,.out, $(TBS_FILES)))
RESULTS_GNUTLS_XF = $(addprefix results/gnutls/,$(subst .tbs,.out, $(TBS_FILES)))
RESULTS_NSS_XF = $(addprefix results/nss/,$(subst .tbs,.out, $(TBS_FILES)))
RESULTS_CERTCHECK_XF = $(addprefix results/certcheck/,$(subst .tbs,.out, $(TBS_FILES)))
RESULTS_GOX509_XF = $(addprefix results/gox509/,$(subst .tbs,.out, $(TBS_FILES)))

RESULTS_OPENSSL = $(RESULTS_OPENSSL_OK) $(RESULTS_OPENSSL_XF)
RESULTS_GNUTLS = $(RESULTS_GNUTLS_OK) $(RESULTS_GNUTLS_XF)
RESULTS_NSS = $(RESULTS_NSS_OK) $(RESULTS_NSS_XF)
RESULTS_CERTCHECK = $(RESULTS_CERTCHECK_OK) $(RESULTS_CERTCHECK_XF)
RESULTS_GOX509 = $(RESULTS_GOX509_OK) $(RESULTS_GOX509_XF)

ifneq ($(strip $(OPENSSL)),)
RESULTS_OK += $(RESULTS_OPENSSL_OK)
RESULTS_XF += $(RESULTS_OPENSSL_XF)
RESULTS += $(RESULTS_OPENSSL)
RESULTS_OK += $(RESULTS_OPENSSL_OK)
endif

ifneq ($(strip $(CERTTOOL)),)
RESULTS_OK += $(RESULTS_GNUTLS_OK)
RESULTS_XF += $(RESULTS_GNUTLS_XF)
RESULTS += $(RESULTS_GNUTLS)
RESULTS_OK += $(RESULTS_GNUTLS_OK)
endif

ifneq ($(strip $(CERTUTIL)),)
RESULTS_OK += $(RESULTS_NSS_OK)
RESULTS_XF += $(RESULTS_NSS_XF)
RESULTS += $(RESULTS_NSS)
RESULTS_OK += $(RESULTS_NSS_OK)
endif

ifneq ($(strip $(CERTCHECK)),)
RESULTS_OK += $(RESULTS_CERTCHECK_OK)
RESULTS_XF += $(RESULTS_CERTCHECK_XF)
RESULTS += $(RESULTS_CERTCHECK)
RESULTS_OK += $(RESULTS_CERTCHECK_OK)
endif

ifneq ($(strip $(GOX509)),)
RESULTS_OK += $(RESULTS_GOX509_OK)
RESULTS_XF += $(RESULTS_GOX509_XF)
RESULTS += $(RESULTS_GOX509)
RESULTS_OK += $(RESULTS_GOX509_OK)
endif

all: check

check: $(RESULTS) check-ok check-xf
check-ok: $(RESULTS_OK)
	@scripts/display Valid
check-xf: $(RESULTS_XF)
	@scripts/display Invalid
check-openssl: check-openssl-ok check-openssl-xf
check-openssl-ok: $(RESULTS_OPENSSL_OK)
	@scripts/display --tool OpenSSL Valid
check-openssl-xf: $(RESULTS_OPENSSL_XF)
	@scripts/display --tool OpenSSL Invalid
check-gnutls: check-gnutls-ok check-gnutls-xf
check-gnutls-ok: $(RESULTS_GNUTLS_OK)
	@scripts/display --tool GnuTLS Valid
check-gnutls-xf: $(RESULTS_GNUTLS_XF)
	@scripts/display --tool GnuTLS Invalid
check-nss: check-nss-ok check-nss-xf
check-nss-ok: $(RESULTS_NSS_OK)
	@scripts/display --tool NSS Valid
check-nss-xf: $(RESULTS_NSS_XF)
	@scripts/display --tool NSS Invalid
check-certcheck: check-certcheck-ok check-certcheck-xf
check-certcheck-ok: $(RESULTS_CERTCHECK_OK)
	@scripts/display --tool certcheck Valid
check-certcheck-xf: $(RESULTS_CERTCHECK_XF)
	@scripts/display --tool certcheck Invalid
check-gox509: check-gox509-ok check-gox509-xf
check-gox509-ok: $(RESULTS_GOX509_OK)
	@scripts/display --tool gox509 Valid
check-gox509-xf: $(RESULTS_GOX509_XF)
	@scripts/display --tool gox509 Invalid

results-openssl: $(RESULTS_OPENSSL)
results-gnutls: $(RESULTS_GNUTLS)
results-nss: $(RESULTS_NSS)
results-certcheck: $(RESULTS_CERTCHECK)
results-gox509: $(RESULTS_GOX509)

# deps target prepares TLS tools; it depends on the TLS env var.
deps: $(DEPS)
pkg-install:
	sudo apt-get install $(PREREQS)
port-install:
	sudo port install $(PREREQS)
show-tls:
	@echo Using: OpenSSL: $(OPENSSL) GnuTLS: $(CERTTOOL) NSS: $(CERTUTIL) certcheck: $(CERTCHECK) gox509: $(GOX509)


###########################################
# Build a wrapper around the Go x509 library
###########################################
bin:
	mkdir -p $@
bin/gox509: src/gox509/gox509.go | bin
	cd bin && go build ../src/gox509/gox509.go

###########################################
# Run certs through TLS tools
###########################################
results:
	mkdir -p $@
results/openssl:
	mkdir -p $@
results/gnutls:
	mkdir -p $@
results/nss:
	mkdir -p $@
results/certcheck:
	mkdir -p $@
results/gox509:
	mkdir -p $@

results/openssl/%.out: certs/%.pem ca/fake-ca.cert | results/openssl
	scripts/check-openssl $(OPENSSL) verify -x509_strict -CAfile ca/fake-ca.cert $< > $@ 2>&1
results/gnutls/%.out: certs/%.chain.pem ca/fake-ca.cert | results/gnutls
	scripts/check-certtool $(CERTTOOL) --verify-chain --load-ca-certificate ca/fake-ca.cert --infile $< >$@ 2>&1
results/nss/%.out: certs/%.pem | results/nss nss-db/cert8.db
	scripts/check-certutil $(CERTUTIL) $< > $@ 2>&1
results/certcheck/%.out: certs/%.der ca/fake-ca.der | results/certcheck
	scripts/check-certcheck $(CERTCHECK) --root ca/fake-ca.der $< > $@ 2>&1
results/gox509/%.out: certs/%.der ca/fake-ca.der | results/gox509
	scripts/check-certcheck $(GOX509) --root ca/fake-ca.der $< > $@ 2>&1

results/openssl/%.out: certs2/%.leaf.pem certs2/%.ca.pem ca/fake-ca.cert | results/openssl
	scripts/check-openssl $(OPENSSL) verify -x509_strict -CAfile ca/fake-ca.cert -untrusted certs2/$*.ca.pem certs2/$*.leaf.pem > $@ 2>&1
results/gnutls/%.out: certs2/%.chain.pem ca/fake-ca.cert | results/gnutls
	scripts/check-certtool $(CERTTOOL) --verify-chain --load-ca-certificate ca/fake-ca.cert --infile $< >$@ 2>&1
results/nss/%.out: certs2/%.leaf.pem certs2/%.ca.pem | results/nss nss-db/cert8.db
	scripts/check-certutil $(CERTUTIL) $^ > $@ 2>&1
results/certcheck/%.out: certs2/%.leaf.der certs2/%.ca.der ca/fake-ca.der | results/certcheck
	scripts/check-certcheck $(CERTCHECK) --root ca/fake-ca.der --intermediate certs2/$*.ca.der $< > $@ 2>&1
results/gox509/%.out: certs2/%.leaf.der certs2/%.ca.der ca/fake-ca.der | results/gox509
	scripts/check-certcheck $(GOX509) --root ca/fake-ca.der --intermediate certs2/$*.ca.der $< > $@ 2>&1

show-openssl-%: certs/%.pem
	$(OPENSSL) x509 -inform pem -in $< -text -noout
show-gnutls-%: certs/%.pem
	$(CERTTOOL) --certificate-info --infile $<
show-nss-%: certs/%.pem nss-db/cert8.db
	$(CERTUTIL) -A -d nss-db -n "Cert from $<" -t ,, -i $<
	$(CERTUTIL) -L -d nss-db -n "Cert from $<"
	$(CERTUTIL) -D -d nss-db -n "Cert from $<"
show-certcheck-%: certs/%.der ca/fake-ca.der
	$(CERTCHECK) --verbose --root ca/fake-ca.der $<
show-gox509-%: certs/%.der ca/fake-ca.der
	$(GOX509) --verbose --root ca/fake-ca.der $<

show2-openssl-%: certs2/%.leaf.pem certs2/%.ca.pem
	$(OPENSSL) x509 -inform pem -in certs2/$*.ca.pem -text -noout
	$(OPENSSL) x509 -inform pem -in certs2/$*.leaf.pem -text -noout


###########################################
# Fake CA set-up; uses OpenSSL as the most
# familiar tool.
###########################################
# Generate a keypair.  Note that these are *not* secret and *not* password-protected.
ca:
	mkdir -p $@
ca/fake-ca.private.pem: | ca
	$(OPENSSL) genpkey -algorithm RSA -out $@ -pkeyopt rsa_keygen_bits:2048
ca/%.public.pem: ca/%.private.pem
	$(OPENSSL) rsa -pubout -in $< -out $@
# Generate a self-signed certificate.
ca/fake-ca.cert: ca/fake-ca.private.pem cfg/fake-ca.cnf
	$(OPENSSL) req -new -x509 -config cfg/fake-ca.cnf -set_serial 0x0406cafe -days 365 -extensions v3_ca -inform pem -key $< -out $@
ca/fake-ca.der: ca/fake-ca.cert
	$(OPENSSL) x509 -in $< -outform der -out $@
ca/fake-ca.ascii: ca/fake-ca.der
	der2ascii -i $< -o $@
# Show fake CA information.
show-ca-privkey: ca/fake-ca.private.pem
	$(OPENSSL) rsa -in $< -text -noout
show-ca-pubkey: ca/fake-ca.public.pem
	$(OPENSSL) rsa -pubin -in $< -text -noout
show-ca-cert: ca/fake-ca.cert
	$(OPENSSL) x509 -inform pem -in $< -text -noout

###########################################
# NSS database setup
###########################################
nss-db:
	mkdir -p $@
nss-db/cert8.db : ca/fake-ca.cert | nss-db
	$(CERTUTIL) -d nss-db -A -n "Fake CA" -t C,, -i $<
show-nssdb-ca: nss-db/cert8.db
	$(CERTUTIL) -d nss-db -L -n "Fake CA"
show-nssdb: nss-db/cert8.db
	$(CERTUTIL) -d nss-db -L

###########################################
# Certificate generation rules.
###########################################
# Rules for certs signed by fake root CA
certs:
	mkdir -p $@
certs/%.ascii: tbs/%.tbs ca/fake-ca.private.pem scripts/tbs2cert | certs
	scripts/tbs2cert -I tbs/fragment -p ca/fake-ca.private.pem $< > $@
certs/%.der: certs/%.ascii
	ascii2der -i $< -o $@
certs/%.pem: certs/%.der
	scripts/der2pem $< > $@
certs/%.chain.pem: certs/%.pem ca/fake-ca.cert
	cat $< ca/fake-ca.cert > $@
# Rules for certs signed by intermediate CA
certs2:
	mkdir -p $@
# CA cert signed by fake root CA
certs2/%.ca.ascii: tbs2/%.ca.tbs ca/fake-ca.private.pem scripts/tbs2cert | certs2
	scripts/tbs2cert -I tbs/fragment -p ca/fake-ca.private.pem $< > $@
# Leaf cert signed by fake intermediate CA
certs2/%.leaf.ascii: tbs2/%.leaf.tbs cfg/fake-intermediate-ca.private.pem scripts/tbs2cert | certs2
	scripts/tbs2cert -I tbs/fragment -p cfg/fake-intermediate-ca.private.pem $< > $@
# special case: use DSA key
certs2/ok-inherited-keyparams.leaf.ascii: tbs2/ok-inherited-keyparams.leaf.tbs cfg/fake-intermediate-ca-dsa.private.pem scripts/tbs2cert | certs2
	scripts/tbs2cert -I tbs/fragment -p cfg/fake-intermediate-ca-dsa.private.pem $< > $@
certs2/%.der: certs2/%.ascii
	ascii2der -i $< -o $@
certs2/%.pem: certs2/%.der
	scripts/der2pem $< > $@
certs2/%.chain.pem: certs2/%.leaf.pem certs2/%.ca.pem ca/fake-ca.cert
	cat $^ > $@


###########################################
# Tidy-up.
###########################################
clean-openssl:
	rm -rf results/openssl
clean-gnutls:
	rm -rf results/gnutls
clean-nss:
	rm -rf results/nss
clean-certcheck:
	rm -rf results/certcheck
clean-gox509:
	rm -rf results/gox509
clean:
	rm -f scripts/*.pyc
	rm -rf results
	rm -rf certs
	rm -rf certs2
	rm -rf nss-db

distclean: clean
	rm -rf ca
	rm -rf bin

.SECONDARY:  # Keep intermediates
.NOTPARALLEL:  # NSS uses a shared cert database, so parallel cert checking causes problems
