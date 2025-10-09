SUMMARY = "Apache Maven (native)"
HOMEPAGE = "https://maven.apache.org/"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${WORKDIR}/Apache-2.0;md5=3b83ef96387f14655fc854ddc3c6bd57"

SRC_URI = " \
    https://archive.apache.org/dist/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz;subdir=${BPN}-${PV} \
    file://Apache-2.0 \
"
SRC_URI[sha256sum] = "6eedd2cae3626d6ad3a5c9ee324bd265853d64297f07f033430755bd0e0c3a4b"
S = "${WORKDIR}/${BPN}-${PV}/apache-maven-${PV}"

inherit java

do_configure[noexec] = "1"
do_compile[noexec] = "1"

do_install() {
    install -d ${D}${bindir} ${D}${datadir}/${BPN}
    cp -a ${S}/* ${D}${datadir}/${BPN}/
    ln -sf ../share/${BPN}/bin/mvn ${D}${bindir}/mvn
}

FILES:${PN} = " \
    ${bindir}/mvn \
    ${datadir}/${BPN} \
"

inherit native
