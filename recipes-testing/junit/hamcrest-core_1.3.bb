SUMMARY = "Hamcrest Core 1.3 (Java matchers)"
HOMEPAGE = "http://hamcrest.org/"
SECTION = "java"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://${WORKDIR}/BSD-3-Clause;md5=71f739ef75581cae312e8c711bcdab16"

SRC_URI = " \
    https://repo1.maven.org/maven2/org/hamcrest/hamcrest-core/1.3/hamcrest-core-1.3-sources.jar;downloadfilename=hamcrest-core-sources.jar;subdir=${BPN}-${PV}  \   
    file://BSD-3-Clause \
    file://0001-hamcrest-1.3-fix-generics-anyOf-allOf-inference.patch \
"
SRC_URI[sha256sum] = "e223d2d8fbafd66057a8848cc94222d63c3cedd652cc48eddc0ab5c39c0f84df"

inherit java

JAVA_SOURCES_JARS = "${WORKDIR}/hamcrest-core-sources.jar"
JAVA_JAR_NAME = "hamcrest-core.jar"

BBCLASSEXTEND = "native"
