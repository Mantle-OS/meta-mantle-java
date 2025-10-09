SUMMARY = "JUnit 4 unit testing framework for Java"
HOMEPAGE = "https://junit.org/junit4/"
SECTION = "java"
LICENSE = "EPL-1.0"
LIC_FILES_CHKSUM = "file://${WORKDIR}/EPL-1.0;md5=d0fc088e4e5216422c217d39853d8601"

SRC_URI = " \
    https://repo1.maven.org/maven2/junit/junit/4.13.2/junit-4.13.2-sources.jar;subdir=${BPN}-${PV} \
    file://EPL-1.0 \
"
SRC_URI[sha256sum] = "34181df6482d40ea4c046b063cb53c7ffae94bdf1b1d62695bdf3adf9dea7e3a"

inherit java

DEPENDS:append = " \
    hamcrest-core-native \
"

#JAVA_SOURCES_JARS    = "${WORKDIR}/junit4-sources.jar"
JAVA_ADDITIONAL_JARS = "${STAGING_DATADIR_NATIVE}/java/hamcrest-core.jar"
JAVA_JAR_NAME        = "junit4.jar"

RDEPENDS:${PN} += "hamcrest-core"
RPROVIDES:${PN} += "junit"

BBCLASSEXTEND = "native"
