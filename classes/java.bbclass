S ??= "${WORKDIR}/${BPN}-${PV}"

#inherit java-licenses

JAVA_VERSION           = "17"
# classfile + API level via --release
JAVA_TARGET_VERSION    ?= "8"
JAVA_SOURCE_DIRS       ?= "${S}"
JAVA_JAR_NAME          ?= "${BPN}.jar"
JAVA_INSTALL_DIR       ?= "${datadir}/java"
JAVA_ADDITIONAL_JARS   ?= ""
JAVA_SOURCES_JARS      ?= ""
JAVA_MAIN_CLASS        ?= ""
JAVA_WRAPPER_NAME      ?= "${BPN}"
JAVA_BUILD_JDK         ?= "openjdk-${JAVA_VERSION}-jdk"
JAVA_EXCLUDE_DIRS      ?= ".pc .git .hg .svn target build out META-INF"

# Use native toolchain; put it first on PATH
PATH:prepend = "${STAGING_BINDIR_NATIVE}:"

# Tools: bindir-native is layout-agnostic
export JAVAC = "${STAGING_BINDIR_NATIVE}/javac"
export JAR   = "${STAGING_BINDIR_NATIVE}/jar"
export JAVA  = "${STAGING_BINDIR_NATIVE}/java"

DEPENDS += " \
    ${JAVA_BUILD_JDK}-native \
"

JAVA_SOURCE_FLAGS = "--release ${JAVA_TARGET_VERSION} -encoding UTF-8"

do_configure[noexec] = "1"

python() {
    d.setVarFlag('do_compile', 'prefuncs', 'java_host_guard')
}

python java_host_guard() {
    import bb
    path  = d.getVar('PATH') or ''
    bindn = d.getVar('STAGING_BINDIR_NATIVE') or ''
    required = ['java','javac','jar']
    for t in required:
        p = bb.utils.which(path, t)
        if not p:
            bb.fatal("%s not found in PATH" % t)
        if not p.startswith(bindn):
            bb.fatal("%s resolves to host or wrong tree: %s (expected under %s)" % (t, p, bindn))
}

do_compile() {
    rm -rf ${B}/classes
    mkdir -p ${B}/classes

    # Build CLASSPATH from additional jars
    CLASSPATH_STR=""
    for j in ${JAVA_ADDITIONAL_JARS}; do
        [ -f "$j" ] || j="${WORKDIR}/$(basename "$j")"
        [ -f "$j" ] && CLASSPATH_STR="${CLASSPATH_STR:+$CLASSPATH_STR:}$j"
    done
    [ -n "${CLASSPATH_STR}" ] && CP_OPT="-cp ${CLASSPATH_STR}" || CP_OPT=""

    # Collect sources from ${JAVA_SOURCE_DIRS}, excluding quilt/git build junk
    : > ${B}/sources.list
    for d in ${JAVA_SOURCE_DIRS}; do
        find "$d" \
            \( -name .pc -o -name .git -o -name .hg -o -name .svn -o -name target -o -name build -o -name out -o -name META-INF \) -prune -o \
            -type f -name "*.java" -print >> ${B}/sources.list
    done

    if [ ! -s ${B}/sources.list ]; then
        echo "No Java sources found to compile" >&2
        exit 1
    fi

    ${JAVAC} ${JAVA_SOURCE_FLAGS} ${CP_OPT} -d ${B}/classes @"${B}/sources.list"
    ( cd ${B}/classes && ${JAR} cf ${B}/${JAVA_JAR_NAME} . )
}

do_install() {
    install -d ${D}${JAVA_INSTALL_DIR}
    install -m 0644 ${B}/${JAVA_JAR_NAME} ${D}${JAVA_INSTALL_DIR}/${JAVA_JAR_NAME}

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

_JAVA_WRAPPER_FILE ??= ""
python __anonymous__ () {
    main_class = d.getVar("JAVA_MAIN_CLASS") or ""
    if main_class:
        bindir  = d.getVar("bindir")
        wrapper = d.getVar("JAVA_WRAPPER_NAME")
        d.setVar("_JAVA_WRAPPER_FILE", f"{bindir}/{wrapper}")
}


FILES:${PN} += " \
    ${JAVA_INSTALL_DIR}/${JAVA_JAR_NAME} \
    ${_JAVA_WRAPPER_FILE} \
"
