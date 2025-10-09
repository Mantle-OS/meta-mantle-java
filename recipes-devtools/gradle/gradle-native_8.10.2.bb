SUMMARY = "Gradle build tool (native)"
HOMEPAGE = "https://gradle.org/"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${WORKDIR}/Apache-2.0;md5=3b83ef96387f14655fc854ddc3c6bd57"

SRC_URI = " \
    https://services.gradle.org/distributions/gradle-8.10.2-bin.zip;subdir=${BPN}-${PV} \
    file://Apache-2.0 \
"
SRC_URI[sha256sum] = "31c55713e40233a8303827ceb42ca48a47267a0ad4bab9177123121e71524c26"

inherit java 
inherit native

S = "${WORKDIR}/${BPN}-${PV}/gradle-${PV}"

do_configure[noexec] = "1"
do_compile[noexec] = "1"

do_install() {
    install -d ${D}${bindir} ${D}${datadir}/${BPN}
    cp -a ${S}/* ${D}${datadir}/${BPN}/
    ln -sf ../share/${BPN}/bin/gradle ${D}${bindir}/gradle
}

FILES:${PN} = " \
    ${bindir}/gradle \
    ${datadir}/${BPN} \
"
