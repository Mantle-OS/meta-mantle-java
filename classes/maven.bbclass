inherit java

# Where the POM lives
MVN_POM ?= "${S}/pom.xml"

# Goals & flags
MVN_GOALS      ?= "package"
MVN_PROFILES   ?= ""
MVN_SKIP_TESTS ?= "1"
MVN_OFFLINE    ?= "1"

# Local, recipe-scoped repo cache; you can pre-seed it via SRC_URI tarballs
MVN_LOCAL_REPO ?= "${B}/.m2/repository"

# Optional: vendor a repo snapshot:
# SRC_URI += "file://m2-repo.tar.zst"
# do_unpack_append() { mkdir -p ${B}/.m2 && tar -C ${B}/.m2 -I zstd -xf ${WORKDIR}/m2-repo.tar.zst; }

do_configure[noexec] = "1"

do_compile() {
    install -d ${MVN_LOCAL_REPO}
    OFFLINE_FLAG=""
    [ "${MVN_OFFLINE}" = "1" ] && OFFLINE_FLAG="--offline"

    SKIP_TESTS_FLAG=""
    [ "${MVN_SKIP_TESTS}" = "1" ] && SKIP_TESTS_FLAG="-DskipTests"

    export JAVA_HOME="${STAGING_LIBDIR_NATIVE}/jvm/${@d.getVar('JAVA_BUILD_JDK').split(':')[-1]}"
    export MAVEN_OPTS="-Duser.home=${B}/.m2"
    export PATH="${STAGING_BINDIR_NATIVE}:$PATH"

    cd ${S}
    mvn -Dmaven.repo.local=${MVN_LOCAL_REPO} ${OFFLINE_FLAG} ${SKIP_TESTS_FLAG} \
        ${@' -P %s' % d.getVar('MVN_PROFILES') if d.getVar('MVN_PROFILES') else ''} \
        ${MVN_GOALS}
}

# Default install: drop built jars into ${datadir}/java (override per recipe if needed)
do_install() {
    install -d ${D}${datadir}/java
    find ${S} -type f -name "*.jar" -maxdepth 3 -print -exec cp -a {} ${D}${datadir}/java/ \;
}

# Guard: don’t allow network during do_compile when offline requested
python() {
    if d.getVar('MVN_OFFLINE') == '1':
        # bitbake-network sandboxing is separate, but we warn loudly
        bb.note("maven.bbclass: offline mode ON; ensure repo is pre-seeded via SRC_URI if dependencies are needed.")
}
