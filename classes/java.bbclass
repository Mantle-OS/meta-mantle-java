# Features:
# - Compiles Java sources (or Maven -sources jars) with javac/jar from native JDK
# - Emits bytecode with configurable -source/-target (defaults to Java 8)
# - Guards against host leakage (java/javac/jar must come from STAGING native)
# - Installs a library jar to ${datadir}/java by default
# - Optional wrapper script for applications (set JAVA_MAIN_CLASS)
# - Works for both target and native (artifact is arch-neutral)
#
# Variables you can override in a recipe:
#   JAVA_VERSION              ?= "17"              # Temurin JDK version in dependency name
#   JAVA_SOURCE_VERSION       ?= "8"               # javac -source
#   JAVA_TARGET_VERSION       ?= "8"               # javac -target
#   JAVA_BUILD_JDK            ?= "openjdk-${JAVA_VERSION}-jdk-native"
#   JAVA_INSTALL_DIR          ?= "${datadir}/java" # where to place the jar
#   JAVA_JAR_NAME             ?= "${BPN}.jar"      # output jar file name
#   JAVA_SOURCE_DIRS          ?= "."               # space-separated source roots
#   JAVA_ADDITIONAL_JARS      ?= ""                # extra classpath jars (absolute paths)
#   JAVA_SOURCES_JARS         ?= ""                # list of *-sources.jar to unpack then compile
#   JAVA_MAIN_CLASS           ?= ""                # if set, generate a wrapper and mark as app
#   JAVA_WRAPPER_NAME         ?= "${BPN}"         # /usr/bin wrapper name if MAIN_CLASS set

########################
# Dependencies & setup #
########################

DEPENDS += "${JAVA_BUILD_JDK}"

# Resolve whether we are building the "native" variant (class-native)
JAVA_IS_NATIVE = "${@'1' if 'native' in d.getVar('CLASSOVERRIDE','') else '0'}"

# Tool roots: always use native JDK for building (even for target package)
JAVA_HOME_NATIVE = "${STAGING_LIBDIR_NATIVE}/jvm"
export JAVA_HOME = "${JAVA_HOME_NATIVE}"
export JAVAC     = "${JAVA_HOME_NATIVE}/bin/javac"
export JAR       = "${JAVA_HOME_NATIVE}/bin/jar"
export PATH      = "${JAVA_HOME_NATIVE}/bin:${PATH}"

##############
# Bytecode   #
##############
JAVA_SOURCE_FLAGS = "-source ${JAVA_SOURCE_VERSION} -target ${JAVA_TARGET_VERSION} -encoding UTF-8"

##############
# Tasks      #
##############
do_configure[noexec] = "1"

# Guard: ensure we never pull host tools
python() {
    # Run early so any task will fail fast
    d.setVarFlag('do_compile', 'prefuncs', 'java_host_guard')
}

python java_host_guard() {
    import bb, os
    path = d.getVar('PATH')
    stage = d.getVar('STAGING_LIBDIR_NATIVE')
    for t in ('java','javac','jar'):
        p = bb.utils.which(path, t)
        if not p or (stage and stage not in p):
            bb.fatal("%s resolves to host or missing: %s" % (t, p))
}

do_compile() {
    rm -rf ${B}/classes ${B}/src-unpacked
    mkdir -p ${B}/classes ${B}/src-unpacked

    # Unpack any -sources.jar inputs
    for sj in ${JAVA_SOURCES_JARS}; do
        [ -f "$sj" ] || sj="${WORKDIR}/$(basename "$sj")"
        [ -f "$sj" ] && ( cd ${B}/src-unpacked && ${JAR} xf "$sj" )
    done

    # Build CLASSPATH string from additional jars
    CLASSPATH_STR=""
    for j in ${JAVA_ADDITIONAL_JARS}; do
        [ -f "$j" ] || j="${WORKDIR}/$(basename "$j")"
        [ -f "$j" ] && CLASSPATH_STR="${CLASSPATH_STR:+$CLASSPATH_STR:}$j"
    done
    [ -n "${CLASSPATH_STR}" ] && CP_OPT="-cp ${CLASSPATH_STR}" || CP_OPT=""

    # Collect sources (unpacked + explicit source dirs)
    SRCDIRS="${B}/src-unpacked ${JAVA_SOURCE_DIRS}"
    find $SRCDIRS -type f -name "*.java" > ${B}/sources.list || true
    if [ ! -s ${B}/sources.list ]; then
        echo "No Java sources found to compile" >&2
        exit 1
    fi

    # Compile
    ${JAVAC} ${JAVA_SOURCE_FLAGS} ${CP_OPT} -d ${B}/classes @"${B}/sources.list"

    # Jar
    ( cd ${B}/classes && ${JAR} cf ${B}/${JAVA_JAR_NAME} . )
}


do_install() {
    # Install library jar
    install -d ${D}${JAVA_INSTALL_DIR}
    install -m 0644 ${B}/${JAVA_JAR_NAME} ${D}${JAVA_INSTALL_DIR}/${JAVA_JAR_NAME}

    # Optional wrapper for applications
    if [ -n "${JAVA_MAIN_CLASS}" ]; then
        install -d ${D}${bindir}
        cat > ${D}${bindir}/${JAVA_WRAPPER_NAME} <<'EOF'
#!/bin/sh
JAVA_HOME="@JAVA_HOME@"
JVM="$JAVA_HOME/bin/java"
JAR="@JAR_PATH@"
EXTRA="@EXTRA_CLASSPATH@"
if [ -n "$EXTRA" ]; then
  CP="$JAR:$EXTRA"
else
  CP="$JAR"
fi
exec "$JVM" -cp "$CP" @MAIN_CLASS@ "$@"
EOF
        sed -i -e "s|@JAVA_HOME@|${libdir}/jvm|g" \
               -e "s|@JAR_PATH@|${JAVA_INSTALL_DIR}/${JAVA_JAR_NAME}|g" \
               -e "s|@EXTRA_CLASSPATH@|${JAVA_ADDITIONAL_JARS}|g" \
               -e "s|@MAIN_CLASS@|${JAVA_MAIN_CLASS}|g" \
               ${D}${bindir}/${JAVA_WRAPPER_NAME}
        chmod 0755 ${D}${bindir}/${JAVA_WRAPPER_NAME}
    fi
}

FILES:${PN} += " ${JAVA_INSTALL_DIR}/${JAVA_JAR_NAME} "
FILES:${PN} += " ${bindir}/${JAVA_WRAPPER_NAME} "

# defaults
JAVA_VERSION ?= "17"
JAVA_SOURCE_VERSION ?= "8"
JAVA_TARGET_VERSION ?= "8"
JAVA_SOURCE_DIRS ?= "."
JAVA_JAR_NAME ?= "${BPN}.jar"
JAVA_INSTALL_DIR ?= "${datadir}/java"
JAVA_ADDITIONAL_JARS ?= ""
JAVA_SOURCES_JARS ?= ""
JAVA_MAIN_CLASS ?= ""
JAVA_WRAPPER_NAME ?= "${BPN}"

