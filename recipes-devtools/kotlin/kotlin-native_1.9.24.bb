SUMMARY = "Kotlin compiler (native)"
HOMEPAGE = "https://kotlinlang.org/"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${WORKDIR}/Apache-2.0;md5=3b83ef96387f14655fc854ddc3c6bd57"

SRC_URI = " \
    https://github.com/JetBrains/kotlin/releases/download/v${PV}/kotlin-compiler-${PV}.zip;subdir=${BPN}-${PV} \
    file://Apache-2.0 \
"
SRC_URI[sha256sum] = "eb7b68e01029fa67bc8d060ee54c12018f2c60ddc438cf21db14517229aa693b"

DEPENDS += " \
    unzip-native \
    openjdk-17-jdk-native \
"

inherit java
inherit native

S = "${WORKDIR}/${BPN}-${PV}/kotlin-compiler-${PV}"

do_configure[noexec] = "1"
do_compile[noexec] = "1"

do_install() {
    install -d ${D}${libdir}/kotlin/${BPN}-${PV}
    cp -R --no-dereference --preserve=mode,timestamps,links -v "${S}/." "${D}${libdir}/kotlin/${BPN}-${PV}/"

    find "${D}${libdir}/kotlin/${BPN}-${PV}/bin" -type f -name "*.bat" -delete || true
    chmod 0755 "${D}${libdir}/kotlin/${BPN}-${PV}/bin/"* || true

    install -d ${D}${bindir}
    ln -sf ../lib/kotlin/${BPN}-${PV}/bin/kotlinc ${D}${bindir}/kotlinc
    ln -sf ../lib/kotlin/${BPN}-${PV}/bin/kotlin  ${D}${bindir}/kotlin
}

FILES:${PN} = " \
    ${bindir}/kotlinc \
    ${bindir}/kotlin \
    ${libdir}/kotlin/${BPN}-${PV} \
"
