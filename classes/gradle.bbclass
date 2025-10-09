inherit java

GRADLE_BUILD_FILE ?= "${S}/build.gradle"
GRADLE_TASKS      ?= "jar"
GRADLE_OFFLINE    ?= "1"
GRADLE_USER_HOME  ?= "${B}/.gradle"
GRADLE_CACHE      ?= "${GRADLE_USER_HOME}/caches"

# Optional: vendor a gradle cache snapshot
# SRC_URI += "file://gradle-cache.tar.zst"
# do_unpack_append() { mkdir -p ${GRADLE_USER_HOME} && tar -C ${GRADLE_USER_HOME} -I zstd -xf ${WORKDIR}/gradle-cache.tar.zst; }

do_configure[noexec] = "1"

do_compile() {
    install -d ${GRADLE_USER_HOME}
    OFFLINE_FLAG=""
    [ "${GRADLE_OFFLINE}" = "1" ] && OFFLINE_FLAG="--offline"

    export JAVA_HOME="${STAGING_LIBDIR_NATIVE}/jvm/${@d.getVar('JAVA_BUILD_JDK').split(':')[-1]}"
    export GRADLE_USER_HOME="${GRADLE_USER_HOME}"
    export PATH="${STAGING_BINDIR_NATIVE}:$PATH"

    cd ${S}
    gradle ${OFFLINE_FLAG} --no-daemon ${GRADLE_TASKS}
}

do_install() {
    install -d ${D}${datadir}/java
    find ${S}/build/libs -type f -name "*.jar" -print -exec cp -a {} ${D}${datadir}/java/ \; || true
}
