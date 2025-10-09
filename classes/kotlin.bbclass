inherit java

KOTLIN_VERSION ?= "1.9.24"

KOTLIN_HOME_NATIVE ?= "${STAGING_LIBDIR_NATIVE}/kotlin/kotlin-native-${KOTLIN_VERSION}"
KOTLINC ?= "${KOTLIN_HOME_NATIVE}/bin/kotlinc"

KOTLIN_SRC_DIRS ?= "${S}"
KOTLIN_JAR_NAME ?= "${BPN}.jar"
KOTLIN_OUTPUT_DIR ?= "${B}/classes"

KOTLIN_JVM_TARGET ?= "1.8"
KOTLIN_INCLUDE_RUNTIME ?= "0"
KOTLIN_USE_JAVAC ?= "1"

KOTLIN_FLAGS ?= " \
    -jvm-target ${KOTLIN_JVM_TARGET} \
"

KOTLIN_STDLIB ?= "${KOTLIN_HOME_NATIVE}/lib/kotlin-stdlib.jar"

PATH:prepend = "${KOTLIN_HOME_NATIVE}/bin:"

do_configure[noexec] = "1"

python() {
    d.setVarFlag('do_compile', 'prefuncs', 'kotlin_host_guard')
}

python kotlin_host_guard() {
    import bb, os
    path = d.getVar('PATH')
    stage = d.getVar('STAGING_LIBDIR_NATIVE') or ''
    for t in ('kotlinc','java','jar'):
        p = bb.utils.which(path, t)
        if not p or (stage and stage not in p):
            bb.fatal("%s resolves to host or missing: %s" % (t, p))
}

do_compile() {
    rm -rf ${KOTLIN_OUTPUT_DIR} ${B}/sources.list
    mkdir -p ${KOTLIN_OUTPUT_DIR}

    find ${KOTLIN_SRC_DIRS} -type f \( -name "*.kt" -o -name "*.java" \) > ${B}/sources.list || true
    if [ ! -s ${B}/sources.list ]; then
        echo "No Kotlin or Java sources found to compile" >&2
        exit 1
    fi

    CLASSPATH_STR=""
    for j in ${JAVA_ADDITIONAL_JARS}; do
        [ -f "$j" ] || j="${WORKDIR}/$(basename "$j")"
        [ -f "$j" ] && CLASSPATH_STR="${CLASSPATH_STR:+$CLASSPATH_STR:}$j"
    done
    if [ -f "${KOTLIN_STDLIB}" ]; then
        CLASSPATH_STR="${CLASSPATH_STR:+$CLASSPATH_STR:}${KOTLIN_STDLIB}"
    fi
    [ -n "${CLASSPATH_STR}" ] && CP_OPT="-classpath ${CLASSPATH_STR}" || CP_OPT=""

    INCLUDE_RT_OPT=""
    if [ "${KOTLIN_INCLUDE_RUNTIME}" = "1" ]; then
        INCLUDE_RT_OPT="-include-runtime"
    fi

    USE_JAVAC_OPT=""
    if [ "${KOTLIN_USE_JAVAC}" = "1" ]; then
        USE_JAVAC_OPT="-Xuse-javac"
    fi

    ${KOTLINC} ${KOTLIN_FLAGS} ${CP_OPT} ${INCLUDE_RT_OPT} ${USE_JAVAC_OPT} -d ${KOTLIN_OUTPUT_DIR} @"${B}/sources.list"

    ( cd ${KOTLIN_OUTPUT_DIR} && ${JAR} cf ${B}/${KOTLIN_JAR_NAME} . )
}

do_install() {
    install -d ${D}${datadir}/java
    install -m 0644 ${B}/${KOTLIN_JAR_NAME} ${D}${datadir}/java/${KOTLIN_JAR_NAME}

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
               -e "s|@JAR_PATH@|${datadir}/java/${KOTLIN_JAR_NAME}|g" \
               -e "s|@EXTRA_CLASSPATH@|${JAVA_ADDITIONAL_JARS}|g" \
               -e "s|@MAIN_CLASS@|${JAVA_MAIN_CLASS}|g" \
               ${D}${bindir}/${JAVA_WRAPPER_NAME}
        chmod 0755 ${D}${bindir}/${JAVA_WRAPPER_NAME}
    fi
}

FILES:${PN} += " \
    ${datadir}/java/${KOTLIN_JAR_NAME} \
    ${bindir}/${JAVA_WRAPPER_NAME} \
"
