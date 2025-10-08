SUMMARY = "JUnit 4 - unit testing framework for Java (built from sources)"
LICENSE = "EPL-1.0"
LIC_FILES_CHKSUM = "file://LICENSE-EPL-1.0;md5=<fill>"

inherit java

# Fetch source jars (arch-independent)
SRC_URI = "\
  https://repo1.maven.org/maven2/junit/junit/4.13.2/junit-4.13.2-sources.jar;downloadfilename=junit4-sources.jar \
  https://repo1.maven.org/maven2/org/hamcrest/hamcrest-core/1.3/hamcrest-core-1.3-sources.jar;downloadfilename=hamcrest-core-sources.jar \
  file://LICENSE-EPL-1.0 \
"
SRC_URI[junit4-sources.jar.sha256sum] = "<fill>"
SRC_URI[hamcrest-core-sources.jar.sha256sum] = "<fill>"

S = "${WORKDIR}"

# Tell the class to unpack sources jars, compile, and jar them up
JAVA_SOURCES_JARS = "${WORKDIR}/hamcrest-core-sources.jar ${WORKDIR}/junit4-sources.jar"

# Two jars will be produced; simplest is to build sequentially:
# 1) Build hamcrest into hamcrest-core.jar, then add it to compile classpath for junit.
# Do this by overriding do_compile:append or split hamcrest into a separate recipe.
# For clarity/simplicity: ship them as two separate recipes in production.
#
# For a single-recipe quickstart, you can set:
# JAVA_ADDITIONAL_JARS = "${WORKDIR}/hamcrest-core.jar"
# and produce hamcrest-core.jar first via a small do_compile:prepend().

# Provide legacy name if something expects 'junit'
RPROVIDES:${PN} += "junit"

# Build both target and native variants
BBCLASSEXTEND = "native"
